defmodule Skoller.Repo.Migrations.CreateClassChangeRequests do
  use Ecto.Migration

  def change do
    create table(:class_change_requests) do
      add :note, :string
      add :is_completed, :boolean, default: false, null: false
      add :class_id, references(:classes, on_delete: :nothing)
      add :class_change_type_id, references(:class_change_types, on_delete: :nothing)

      timestamps()
    end

    create index(:class_change_requests, [:class_id])
    create index(:class_change_requests, [:class_change_type_id])
  end
end
