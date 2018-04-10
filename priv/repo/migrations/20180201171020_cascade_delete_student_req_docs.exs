defmodule Skoller.Repo.Migrations.CascadeDeleteStudentReqDocs do
  use Ecto.Migration

  def change do
    drop constraint("class_student_request_docs", "class_student_request_docs_doc_id_fkey")
    alter table(:class_student_request_docs) do
      modify :doc_id, references(:docs, on_delete: :delete_all)
    end
  end
end
