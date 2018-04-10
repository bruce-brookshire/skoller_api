defmodule Skoller.Repo.Migrations.CreateClassWeights do
  use Ecto.Migration

  def change do
    create table(:class_weights) do
      add :name, :string
      add :weight, :decimal
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:class_weights, [:class_id])
  end
end
