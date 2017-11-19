defmodule Classnavapi.Repo.Migrations.CreateModificationActions do
  use Ecto.Migration

  def change do
    create table(:modification_actions) do
      add :is_accepted, :boolean, default: false, null: false
      add :assignment_modification_id, references(:assignment_modifications, on_delete: :nothing)
      add :student_class_id, references(:student_classes, on_delete: :nothing)

      timestamps()
    end

    create index(:modification_actions, [:assignment_modification_id])
    create index(:modification_actions, [:student_class_id])
    create unique_index(:modification_actions, [:assignment_modification_id, :student_class_id])
  end
end
