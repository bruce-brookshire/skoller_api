defmodule Classnavapi.Repo.Migrations.CreateClassStudentRequests do
  use Ecto.Migration

  def change do
    create table(:class_student_requests) do
      add :notes, :string
      add :is_completed, :boolean, default: false, null: false
      add :class_student_request_type_id, references(:class_student_request_types, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:class_student_requests, [:class_student_request_type_id])
    create index(:class_student_requests, [:class_id])
  end
end
