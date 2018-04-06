defmodule Skoller.Repo.Migrations.CreateRoles do
  
  @moduledoc """

  Defines migration for roles table.

  Columns are :id, bigint
  :name, string

  There is a unique index on name.

  The id is not sequenced.

  """
  
  use Ecto.Migration

  def change do
    create table(:roles, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string

      timestamps()
    end

    create unique_index(:roles, [:name])
  end
end
