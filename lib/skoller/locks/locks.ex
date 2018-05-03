defmodule Skoller.Locks do

  alias Skoller.Repo
  alias Skoller.Locks.Lock
  alias Skoller.Locks.Section
  alias Skoller.Class.AbandonedLock

  import Ecto.Query

  def find_lock(class_id, lock, user_id) do
    from(l in Lock)
    |> where([l], l.class_id == ^class_id and l.user_id == ^user_id and l.is_completed == false)
    |> where([l], l.class_lock_section_id in [^lock])
    |> Repo.all()
    |> List.first()
  end

  def lock_class(class_id, user_id) do
    sections = from(sect in Section)
    |> where([sect], sect.is_diy == true)
    |> Repo.all()

    Ecto.Multi.new
    |> Ecto.Multi.run(:sections, &lock_sections(sections, class_id, user_id, &1))
    |> Repo.transaction()
  end

  def unlock_locks(class_id, user_id, params) do
    from(l in Lock)
    |> where([l], l.class_id == ^class_id and l.user_id == ^user_id and l.is_completed == false)
    |> Repo.all()
    |> Enum.map(&unlock_lock(&1, params))
  end
  def unlock_locks(lock) do
    from(l in Lock)
    |> where([l], l.class_id == ^lock.class_id and l.user_id == ^lock.user_id and l.is_completed == false)
    |> Repo.all()
    |> Enum.map(&unlock_lock(&1, %{}))
  end

  def delete_locks(_class, %{is_complete: true}), do: {:ok, nil}
  def delete_locks(_class, %{is_maintenance: true}), do: {:ok, nil}
  def delete_locks(class, _status) do
    {:ok, delete_class_locks(class)}
  end

  def get_incomplete_locks(min) do
    from(lock in Lock)
    |> where([lock], lock.is_completed == false)
    |> where([lock], lock.inserted_at < ago(^min, "minute"))
    |> Repo.all()
  end

  defp lock_sections(sections, class_id, user_id, _) do
    sections
    |> Enum.map(&lock_section(class_id, user_id, &1.id))
  end

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