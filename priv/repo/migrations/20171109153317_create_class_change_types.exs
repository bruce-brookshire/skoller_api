defmodule Classnavapi.Repo.Migrations.CreateClassChangeTypes do
  use Ecto.Migration

  def change do
    create table(:class_change_types, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string

      timestamps()
    end

    create unique_index(:class_change_types, [:name])
  end
end
