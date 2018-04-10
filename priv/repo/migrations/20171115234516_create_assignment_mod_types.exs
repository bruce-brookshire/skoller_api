defmodule Skoller.Repo.Migrations.CreateAssignmentModTypes do
  use Ecto.Migration

  def change do
    create table(:assignment_mod_types, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string

      timestamps()
    end

    create unique_index(:assignment_mod_types, [:name])
  end
end
