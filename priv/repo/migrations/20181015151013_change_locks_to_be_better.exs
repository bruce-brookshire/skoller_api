defmodule Skoller.Repo.Migrations.ChangeLocksToBeBetter do
  use Ecto.Migration

  import Ecto.Query
  alias Skoller.Repo
  alias Skoller.Locks.Lock
  alias Skoller.Weights.Weight
  alias Skoller.Assignments.Assignment

  def change do
    locks = from(l in Lock)
    |> where([l], l.is_completed == true)
    |> Repo.all()

    alter table(:class_locks) do
      remove :is_completed

      add :class_lock_subsection, :id
    end

    alter table(:class_weights) do
      add :created_by, references(:users, on_delete: :nilify_all)
      add :updated_by, references(:users, on_delete: :nilify_all)
      add :created_on, :string
    end

    alter table(:assignments) do
      add :created_by, references(:users, on_delete: :nilify_all)
      add :updated_by, references(:users, on_delete: :nilify_all)
      add :created_on, :string
    end

    alter table(:classes) do
      add :created_by, references(:users, on_delete: :nilify_all)
      add :updated_by, references(:users, on_delete: :nilify_all)
      add :created_on, :string
    end

    drop table(:class_abandoned_locks)

    flush()
    locks |> Enum.each(&process_lock(&1))
  end

  defp process_lock(%{class_lock_section_id: 100, user_id: user_id} = lock) do
    from(w in Weight)
    |> where([w], w.class_id == ^lock.class_id)
    |> update(set: [created_by: ^user_id, updated_by: ^user_id, created_on: "Web"])
    |> Repo.update_all([])

    lock |> Repo.delete!()
  end
  defp process_lock(%{class_lock_section_id: 200, user_id: user_id} = lock) do
    from(a in Assignment)
    |> where([a], a.class_id == ^lock.class_id)
    |> update(set: [created_by: ^user_id, updated_by: ^user_id, created_on: "Web"])
    |> Repo.update_all([])

    lock |> Repo.delete!()
  end
  defp process_lock(lock), do: lock |> Repo.delete!()
end
