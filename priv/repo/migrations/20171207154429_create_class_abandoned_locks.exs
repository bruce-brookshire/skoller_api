defmodule Classnavapi.Repo.Migrations.CreateClassAbandonedLocks do
  use Ecto.Migration

  def change do
    create table(:class_abandoned_locks) do
      add :class_lock_section_id, references(:class_lock_sections, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:class_abandoned_locks, [:class_lock_section_id])
    create index(:class_abandoned_locks, [:class_id])
    create index(:class_abandoned_locks, [:user_id])
  end
end
