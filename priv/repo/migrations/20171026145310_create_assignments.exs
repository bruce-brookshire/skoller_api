defmodule Skoller.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments) do
      add :name, :string
      add :due, :date
      add :weight_id, references(:class_weights, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:assignments, [:class_id])
    create index(:assignments, [:weight_id])

    create table(:student_assignments) do
      add :name, :string
      add :due, :date
      add :weight_id, references(:class_weights, on_delete: :nothing)
      add :student_class_id, references(:student_classes, on_delete: :nothing)
      add :assignment_id, references(:assignments, on_delete: :nothing)
      add :grade, :decimal

      timestamps()
    end

    create index(:student_assignments, [:student_class_id])
    create index(:student_assignments, [:weight_id])
    create index(:student_assignments, [:assignment_id])
  end
end
