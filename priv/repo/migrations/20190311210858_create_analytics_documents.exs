defmodule Skoller.Repo.Migrations.CreateAnalyticsDocuments do
  use Ecto.Migration
  alias Skoller.Analytics.Documents.DocumentType

  def up do

    create table(:analytics_document_types) do
      add :name, :string
      add :time, :string
      timestamps()
    end

    flush()

    Skoller.Repo.insert(%DocumentType{id: 100, name: "User Analytics", time: "22:00:00"})
    Skoller.Repo.insert(%DocumentType{id: 200, name: "Class Analytics", time: "22:00:00"})
    Skoller.Repo.insert(%DocumentType{id: 300, name: "School Analytics", time: "22:00:00"})

    flush()

    create table(:analytics_documents) do
      add :path, :string
      add :analytics_document_type_id, references(:analytics_document_types, on_delete: :nothing)
      timestamps()
    end

  end

  def down do
    drop constraint(:analytics_documents, :analytics_documents_analytics_document_type_id_fkey)
    drop table(:analytics_document_types)
    drop table(:analytics_documents)
  end
end
