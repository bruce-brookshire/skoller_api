defmodule Classnavapi.Repo.Migrations.CreateAssignmentModifications do
  use Ecto.Migration

  def change do
    create table(:assignment_modifications) do
      add :data, :map
      add :is_private, :boolean, default: false, null: false
      add :assignment_id, references(:assignments, on_delete: :nothing)
      add :assignment_mod_type_id, references(:assignment_mod_types, on_delete: :nothing)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:assignment_modifications, [:assignment_id])
    create index(:assignment_modifications, [:assignment_mod_type_id])
    create index(:assignment_modifications, [:student_id])

    alter table(:assignments) do
      add :from_mod, :boolean, default: false, null: false
    end

    create unique_index(:student_assignments, [:student_class_id, :assignment_id])
  end
end
