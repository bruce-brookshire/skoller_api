defmodule Classnavapi.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles, primary_key: false) do
      add :id, :integer, primary_key: true
      add :name, :string

      timestamps()
    end

    create unique_index(:roles, [:name])
  end
end
