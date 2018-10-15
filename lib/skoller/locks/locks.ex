defmodule Skoller.Locks do
  @moduledoc """
  Context module for locks.
  """

  alias Skoller.Repo
  alias Skoller.Locks.Lock
  alias Skoller.Locks.Section
  alias Skoller.Locks.AbandonedLock
  alias Skoller.MapErrors
  alias Skoller.Classes.Weights
  alias Skoller.Classes.Assignments

  import Ecto.Query

  @weight_lock 100
  @assignment_lock 200

  @doc """
  Finds existing locks for the class and user.

  ## Returns
  `[Skoller.Locks.Lock]` or `[]`
  """
  def find_lock(class_id, lock_section, user_id, subsection \\ nil)
  def find_lock(class_id, lock_section, user_id, nil) do
    from(l in Lock)
    |> where([l], l.class_id == ^class_id and l.class_lock_section_id == ^lock_section and l.user_id == ^user_id)
    |> Repo.all()
  end
  def find_lock(class_id, lock_section, user_id, subsection) do
    Repo.get_by(Lock,
      class_id: class_id,
      class_lock_section_id: lock_section,
      user_id: user_id,
      class_lock_subsection: subsection)
    |> List.wrap()
  end

  @doc """
  Locks a full class for a user.

  ## Returns
  `{:ok, %{sections: Skoller.Locks.Section}}` or `{:error, _, _, _}`
  """
  def lock_class(class_id, user_id, nil) do
    sections = from(sect in Section)
    |> where([sect], sect.is_diy == true)
    |> Repo.all()

    Ecto.Multi.new
    |> Ecto.Multi.run(:sections, &lock_sections(sections, class_id, user_id, &1))
    |> Repo.transaction()
  end
  def lock_class(class_id, user_id, :weights) do
    case lock_section(class_id, user_id, @weight_lock) do
      {:ok, section} -> 
        map = Map.new() |> Map.put(:sections, List.wrap(section))
        {:ok, map}
      {:error, error} -> {:error, nil, error, nil}
    end
  end
  def lock_class(class_id, user_id, :assignments) do
    case lock_section(class_id, user_id, @assignment_lock) do
      {:ok, section} -> 
        map = Map.new() |> Map.put(:sections, List.wrap(section))
        {:ok, map}
      {:error, error} -> {:error, nil, error, nil}
    end
  end

  @doc """
  Unlocks a class.

  ## Params
   * `%{"is_completed" => Boolean}`, if true, will complete locks and advance status. If false, will abandon locks.

  ## Returns
  `[{:ok, Skoller.Locks.Lock}]`
  """
  def unlock_locks(class_id, user_id, params) do
    from(l in Lock)
    |> where([l], l.class_id == ^class_id and l.user_id == ^user_id and l.is_completed == false)
    |> Repo.all()
    |> Enum.map(&unlock_lock(&1, params))
  end

  @doc """
  Unlocks a class to abandon locks that are `min` old and incomplete.

  ## Returns
  `[{:ok, Skoller.Locks.Lock}]`
  """
  def clear_locks(min) do
    case get_incomplete_locks(min) do
      [] -> {:ok, nil}
      locks -> 
        locks |> Enum.map(&unlock_lock(&1, %{}))
    end
  end

  @doc """
  Deletes locks for a class based on the new status.

  ## Returns
  `{:ok, Tuple}` or `{:ok, nil}`
  """
  def delete_locks(class, new_status)
  def delete_locks(_class, %{is_complete: true}), do: {:ok, nil}
  def delete_locks(_class, %{is_maintenance: true}), do: {:ok, nil}
  def delete_locks(class, _status) do
    {:ok, delete_class_locks(class)}
  end

  defp get_completed_lock_by_section(class_id, class_lock_section_id) do
    Repo.get_by(Lock,
      class_id: class_id,
      class_lock_section_id: class_lock_section_id,
      is_completed: true)
  end

  # Gets locks that are incomplete after `min` minutes.
  defp get_incomplete_locks(min) do
    from(lock in Lock)
    |> where([lock], lock.is_completed == false)
    |> where([lock], lock.inserted_at < ago(^min, "minute"))
    |> Repo.all()
  end

  # Locks the sections passed in.
  defp lock_sections(sections, class_id, user_id, _) do
    status = sections
    |> Enum.map(&lock_section(class_id, user_id, &1.id))

    status
    |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  #Locks the section if it is not already locked.
  defp lock_section(class_id, user_id, class_lock_section_id) do
    case find_lock(class_id, class_lock_section_id, user_id) do
      nil -> create_new_lock(class_id, user_id, class_lock_section_id)
      lock -> {:ok, lock} 
    end
  end

  defp evaluate_completed_locks(class_id, @weight_lock) do
    case Weights.get_class_weights(class_id) do
      [] -> get_completed_lock_by_section(class_id, @weight_lock)
      _weights -> nil
    end
  end
  defp evaluate_completed_locks(class_id, @assignment_lock) do
    case Assignments.all(class_id) do
      [] -> get_completed_lock_by_section(class_id, @assignment_lock)
      _weights -> nil
    end
  end
  defp evaluate_completed_locks(_class_id, _class_lock_section_id), do: nil

  defp create_new_lock(class_id, user_id, class_lock_section_id) do
    case evaluate_completed_locks(class_id, class_lock_section_id) do
      nil -> nil
      lock -> lock |> delete_lock()
    end
    changeset = Lock.changeset(%Lock{}, %{
      class_id: class_id, 
      class_lock_section_id: class_lock_section_id, 
      user_id: user_id
    }) 
    Repo.insert(changeset)
  end
  
  defp unlock_lock(lock_old, %{"is_completed" => true}) do
    changeset = Lock.changeset(lock_old, %{is_completed: true})
    Repo.update(changeset)
  end

  defp unlock_lock(lock_old, %{}) do
    Repo.insert!(%AbandonedLock{
      class_lock_section_id: lock_old.class_lock_section_id,
      class_id: lock_old.class_id,
      user_id: lock_old.user_id
    })
    Repo.delete(lock_old)
  end

  defp delete_class_locks(class) do
    from(l in Lock)
    |> where([l], l.class_id == ^class.id)
    |> Repo.delete_all()
  end

  defp delete_lock(lock) do
    lock |> Repo.delete()
  end
end