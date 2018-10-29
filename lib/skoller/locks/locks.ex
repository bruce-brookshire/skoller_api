defmodule Skoller.Locks do
  @moduledoc """
  Context module for locks.
  """

  alias Skoller.Repo
  alias Skoller.Locks.Lock
  alias Skoller.Locks.Section
  alias Skoller.MapErrors
  alias Skoller.Classes.Weights
  alias Skoller.Locks.Users
  alias Skoller.ClassStatuses.Classes

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

  If the class `is_completed` it will update the class status accordingly.

  ## Returns
  `{:ok, %{unlock: unlocked locks, status: ClassStatuses.check_status/2}}` or an Ecto.Multi error
  """
  def unlock_class(old_class, user_id, is_completed) do
    locks = Users.get_locks_by_class_and_user(old_class.id, user_id)

    Ecto.Multi.new
    |> Ecto.Multi.run(:unlock, &unlock_locks(locks, &1))
    |> Ecto.Multi.run(:status, &check_class_status(&1, old_class, is_completed))
    |> Repo.transaction()
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
        locks |> unlock_locks()
    end
  end

  defp check_class_status(multi_params, old_class, is_completed) when is_completed == true do
    Classes.check_status(old_class, multi_params)
  end
  defp check_class_status(_multi_params, _old_class, _is_completed), do: {:ok, nil}

  defp unlock_locks(locks, _), do: unlock_locks(locks)
  defp unlock_locks(locks) do
    status = locks |> Enum.map(&delete_lock(&1))

    status
    |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
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

    status = status ++ List.wrap(lock_section(class_id, user_id, @assignment_lock, nil))

    status
    |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
  defp lock_full_section(class_id, user_id, class_lock_section_id) do
    lock_section(class_id, user_id, class_lock_section_id, nil)
  end

  #Locks the section if it is not already locked.
  defp lock_section(class_id, user_id, class_lock_section_id, subsection) do
    case find_lock(class_id, class_lock_section_id, user_id, subsection) do
      [] -> create_new_lock(class_id, user_id, class_lock_section_id, subsection)
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

  defp delete_lock(lock) do
    lock |> Repo.delete()
  end
end