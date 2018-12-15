defmodule Skoller.Repo.Migrations.ChangeLocksToBeBetter do
  @moduledoc false
  use Ecto.Migration

  import Ecto.Query
  alias Skoller.Repo
  alias Skoller.Locks.Lock
  alias Skoller.Weights.Weight
  alias Skoller.Assignments.Assignment

  def change do
    locks = from(l in Lock)
    |> where([l], fragment("is_completed = true"))
    |> select([l], %{id: l.id, class_lock_section_id: l.class_lock_section_id, user_id: l.user_id, class_id: l.class_id})
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
    drop unique_index(:class_locks, [:class_id, :class_lock_section_id])

    create unique_index(:class_locks, [:class_id, :class_lock_section_id, :class_lock_subsection], name: :unique_class_user_section_lock_idx)

    flush()
    locks |> Enum.each(&process_lock(&1))
  end

  defp process_lock(%{class_lock_section_id: 100, user_id: user_id} = lock) do
    from(w in Weight)
    |> where([w], w.class_id == ^lock.class_id)
    |> update(set: [created_by: ^user_id, updated_by: ^user_id, created_on: "Web"])
    |> Repo.update_all([])

    Repo.get!(Lock, lock.id)
    |> Repo.delete!()
  end
  defp process_lock(%{class_lock_section_id: 200, user_id: user_id} = lock) do
    from(a in Assignment)
    |> where([a], a.class_id == ^lock.class_id)
    |> update(set: [created_by: ^user_id, updated_by: ^user_id, created_on: "Web"])
    |> Repo.update_all([])

    Repo.get!(Lock, lock.id)
    |> Repo.delete!()
  end
  defp process_lock(lock), do: Repo.get!(Lock, lock.id) |> Repo.delete!()
end
