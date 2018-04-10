defmodule Skoller.Repo.Migrations.CreateStudentClasses do
  use Ecto.Migration

  def change do
    create table(:student_classes) do
      add :student_id, references(:students, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:student_classes, [:student_id])
    create index(:student_classes, [:class_id])
    create unique_index(:student_classes, [:student_id, :class_id])
  end
end
