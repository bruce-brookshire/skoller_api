defmodule Skoller.Repo.Migrations.CreateClassStatuses do

  @moduledoc """

  Defines migration for class statuses table.

  Columns are :id, bigint
  :name, string
  :is_editable, bool
  :is_complete, bool

  There is a unique index on name.

  The id is not sequenced.

  """

  use Ecto.Migration

  def change do
    create table(:class_statuses, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string
      add :is_complete, :boolean, null: false

      timestamps()
    end

    create unique_index(:class_statuses, [:name])
  end
end
