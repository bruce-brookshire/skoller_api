defmodule Classnavapi.Repo.Migrations.CreateModAutoUpdates do
  use Ecto.Migration

  def change do
    create table(:admin_settings, primary_key: false) do
      add :name, :string, primary_key: true
      add :value, :string

      timestamps()
    end

  end
end
