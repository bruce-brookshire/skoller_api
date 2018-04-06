defmodule Skoller.Repo.Migrations.CreateClassStudentRequestDocs do
  use Ecto.Migration

  def change do
    create table(:class_student_request_docs) do
      add :class_student_request_id, references(:class_student_requests, on_delete: :nothing)
      add :doc_id, references(:docs, on_delete: :nothing)

      timestamps()
    end

    create index(:class_student_request_docs, [:class_student_request_id])
    create index(:class_student_request_docs, [:doc_id])
  end
end
