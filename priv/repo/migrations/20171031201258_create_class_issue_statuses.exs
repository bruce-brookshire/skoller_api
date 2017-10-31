defmodule Classnavapi.Repo.Migrations.CreateClassIssueStatuses do

  @moduledoc """

  Defines migration for class issues statuses table.

  Columns are :id, bigint
  :status, string

  There is a unique index on status.

  The id is not sequenced.

  """

  use Ecto.Migration

  def change do
    create table(:class_issue_statuses, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :status, :string

      timestamps()
    end

    create unique_index(:class_issue_statuses, [:status])
  end
end
