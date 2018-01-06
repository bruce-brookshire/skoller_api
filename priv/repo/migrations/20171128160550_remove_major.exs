defmodule Classnavapi.Repo.Migrations.RemoveMajor do
  use Ecto.Migration

  def change do
    alter table(:students) do
      remove :major
    end
  end
end
