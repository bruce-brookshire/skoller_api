defmodule Skoller.Repo.Migrations.CreateStates do
  @moduledoc false
  use Ecto.Migration

  def up do
    create table(:states) do
      add :state_code, :string
      add :name, :string

      timestamps()
    end
  end

  def down do
    drop table(:states)
  end
end
