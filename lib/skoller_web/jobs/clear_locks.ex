defmodule SkollerWeb.Jobs.ClearLocks do
  
  alias Skoller.Repo
  alias Skoller.Class.Lock
  alias Skoller.Class.AbandonedLock

  import Ecto.Query

  @open_lock_mins 60

    def run() do
      locks = get_incomplete_locks()
      locks |> insert_into_abandoned()
      locks |> delete()
    end

    defp delete(locks) do
      locks |> Enum.each(&Repo.delete!(&1))
    end

    defp insert_into_abandoned(locks) do
      locks |> Enum.each(&Repo.insert!(%AbandonedLock{
        class_lock_section_id: &1.class_lock_section_id,
        class_id: &1.class_id,
        user_id: &1.user_id
      }))
    end

    defp get_incomplete_locks() do
      from(lock in Lock)
      |> where([lock], lock.is_completed == false)
      |> where([lock], lock.inserted_at < ago(^@open_lock_mins, "minute"))
      |> Repo.all
    end
end