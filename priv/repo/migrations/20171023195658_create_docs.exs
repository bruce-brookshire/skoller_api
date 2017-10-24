defmodule Classnavapi.Repo.Migrations.CreateDocs do
  use Ecto.Migration

  def change do
    create table(:docs) do
      add :path, :string
      add :name, :string
      add :is_syllabus, :boolean, default: false, null: false
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:docs, [:class_id])
  end
end
