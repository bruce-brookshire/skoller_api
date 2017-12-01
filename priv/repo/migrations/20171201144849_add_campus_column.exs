defmodule Classnavapi.Repo.Migrations.AddCampusColumn do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :campus, :string
    end
  end
end
