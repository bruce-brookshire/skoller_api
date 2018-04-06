defmodule Skoller.Repo.Migrations.CreateClassLocks do
  use Ecto.Migration

  def change do
    create table(:class_locks) do
      add :is_completed, :boolean, default: false, null: false
      add :class_lock_section_id, references(:class_lock_sections, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:class_locks, [:class_lock_section_id])
    create index(:class_locks, [:class_id])
    create index(:class_locks, [:user_id])
    create unique_index(:class_locks, [:class_id, :class_lock_section_id])
  end
end
