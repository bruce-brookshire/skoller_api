defmodule Skoller.Locks do
  @moduledoc """
  Context module for locks.
  """

  alias Skoller.Repo
  alias Skoller.Locks.Lock
  alias Skoller.Locks.Section
  alias Skoller.MapErrors
  alias Skoller.Classes.Weights

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

  If section is passed, will lock an individual section.

  ## Opts
   * subsection: Denotes a subsection to lock.

  ## Returns
  `{:ok, %{sections: Skoller.Locks.Section}}` or `{:error, _, _, _}`
  """
  def lock_class(class_id, user_id, section \\ nil, opts \\ [])
  def lock_class(class_id, user_id, nil, _opts) do
    sections = Repo.all(Section)

    Ecto.Multi.new
    |> Ecto.Multi.run(:sections, &lock_sections(sections, class_id, user_id, &1))
    |> Repo.transaction()
  end
  def lock_class(class_id, user_id, :weights, _opts) do
    case lock_section(class_id, user_id, @weight_lock, nil) do
      {:ok, sections} -> 
        {:ok, %{sections: sections}}
      {:error, error} -> {:error, nil, error, nil}
    end
  end
  def lock_class(class_id, user_id, :assignments, opts) do
    case lock_section(class_id, user_id, @assignment_lock, Keyword.get(opts, :subsection)) do
      {:ok, sections} -> 
        {:ok, %{sections: sections}}
      {:error, error} -> {:error, nil, error, nil}
    end
  end

  @doc """
  Unlocks a class.

  ## Returns
  `[{:ok, Skoller.Locks.Lock}]`
  """
  def unlock_locks(class_id, user_id) do
    from(l in Lock)
    |> where([l], l.class_id == ^class_id and l.user_id == ^user_id)
    |> Repo.all()
    |> Enum.map(&delete_lock(&1))
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
        locks |> Enum.map(&delete_lock(&1))
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
    |> where([lock], lock.inserted_at < ago(^min, "minute"))
    |> Repo.all()
  end

  # Locks the sections passed in.
  defp lock_sections(sections, class_id, user_id, _) do
    status = sections
    |> Enum.map(&lock_full_section(class_id, user_id, &1.id))

    status
    |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  #Locks all sections and subsections if it is not already locked.
  defp lock_full_section(class_id, user_id, @assignment_lock) do
    status = Weights.get_class_weights(class_id)
    |> Enum.map(&lock_section(class_id, user_id, @assignment_lock, &1.id))

    status
    |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
  defp lock_full_section(class_id, user_id, class_lock_section_id) do
    lock_section(class_id, user_id, class_lock_section_id, nil)
  end

  #Locks the section if it is not already locked.
  defp lock_section(class_id, user_id, class_lock_section_id, subsection) do
    case find_lock(class_id, class_lock_section_id, user_id, subsection) do
      nil -> create_new_lock(class_id, user_id, class_lock_section_id, subsection)
      lock -> {:ok, lock} 
    end
  end

  defp create_new_lock(class_id, user_id, class_lock_section_id, subsection) do
    Lock.changeset(%Lock{}, %{
      class_id: class_id, 
      class_lock_section_id: class_lock_section_id, 
      user_id: user_id,
      class_lock_subsection: subsection
    }) |> Repo.insert()
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