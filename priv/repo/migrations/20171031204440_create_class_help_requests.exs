defmodule Classnavapi.Repo.Migrations.CreateClassHelpRequests do
  use Ecto.Migration

  def change do
    create table(:class_help_requests) do
      add :note, :string
      add :is_completed, :boolean, default: false, null: false
      add :class_id, references(:classes, on_delete: :nothing)
      add :class_help_type_id, references(:class_help_types, on_delete: :nothing)

      timestamps()
    end

    create index(:class_help_requests, [:class_id])
    create index(:class_help_requests, [:class_help_type_id])
  end
end
