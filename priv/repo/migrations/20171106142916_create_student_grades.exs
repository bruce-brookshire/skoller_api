defmodule Classnavapi.Repo.Migrations.CreateStudentGrades do
  use Ecto.Migration

  def change do
    create table(:student_grades) do
      add :grade, :decimal
      add :assignment_id, references(:assignments, on_delete: :nothing)
      add :student_class_id, references(:student_classes, on_delete: :nothing)

      timestamps()
    end

    create index(:student_grades, [:assignment_id])
    create index(:student_grades, [:student_class_id])
    create unique_index(:student_grades, [:assignment_id, :student_class_id])
  end
end
