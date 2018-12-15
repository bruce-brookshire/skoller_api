defmodule Skoller.Repo.Migrations.CreateAdminSettings do
  @moduledoc false
  use Ecto.Migration
  
  def change do
    create table(:admin_settings, primary_key: false) do
      add :name, :string, primary_key: true
      add :topic, :string
      add :value, :string

      timestamps()
    end
  end
end
