defmodule Skoller.Locks do
  @moduledoc """
  Context module for locks.
  """

  alias Skoller.Repo
  alias Skoller.Locks.Lock
  alias Skoller.Locks.Section
  alias Skoller.Class.AbandonedLock
  alias Skoller.MapErrors

  import Ecto.Query

  @doc """
  Finds an existing, incomplete lock for the class and user.

  ## Returns
  `Skoller.Locks.Lock` or `nil`
  """
  def find_lock(class_id, lock_section, user_id) do
    from(l in Lock)
    |> where([l], l.class_id == ^class_id and l.user_id == ^user_id and l.is_completed == false)
    |> where([l], l.class_lock_section_id == ^lock_section)
    |> Repo.all()
    |> List.first()
  end

  @doc """
  Locks a full class for a user.

  ## Returns
  `{:ok, %{sections: Skoller.Locks.Section}}` or `{:error, _, _, _}`
  """
  def lock_class(class_id, user_id) do
    sections = from(sect in Section)
    |> where([sect], sect.is_diy == true)
    |> Repo.all()

    Ecto.Multi.new
    |> Ecto.Multi.run(:sections, &lock_sections(sections, class_id, user_id, &1))
    |> Repo.transaction()
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
    case Repo.get_by(Lock, class_id: class_id, 
                            class_lock_section_id: class_lock_section_id, 
                            user_id: user_id,
                            is_completed: false) do
      nil ->           
        changeset = Lock.changeset(%Lock{}, %{
          class_id: class_id, 
          class_lock_section_id: class_lock_section_id, 
          user_id: user_id
        }) 
        Repo.insert(changeset)
      lock -> {:ok, lock} 
    end
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
end