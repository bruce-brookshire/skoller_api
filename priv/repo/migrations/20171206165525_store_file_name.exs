defmodule Classnavapi.Repo.Migrations.StoreFileName do
  use Ecto.Migration

  def change do
    alter table(:docs) do
      add :name, :string
    end
  end
end
