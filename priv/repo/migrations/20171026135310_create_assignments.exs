defmodule Classnavapi.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments) do
      add :name, :string
      add :relative_weight, :decimal
      add :due, :date
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:assignments, [:class_id])
  end
end
