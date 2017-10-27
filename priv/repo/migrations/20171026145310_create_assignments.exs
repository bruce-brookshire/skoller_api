defmodule Classnavapi.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments) do
      add :name, :string
      add :due, :date
      add :weight_id, references(:class_weights, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:assignments, [:class_id])
    create index(:assignments, [:weight_id])
  end
end
