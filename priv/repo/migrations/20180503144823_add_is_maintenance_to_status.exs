defmodule Skoller.Repo.Migrations.AddIsMaintenanceToStatus do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.ClassesStatuses.Status

  def change do
    alter table(:class_statuses) do
      add :is_maintenance, :boolean, default: false, null: false
    end
    flush()
    case Repo.get(Status, 600) do
      nil -> nil
      item -> item
        |> Ecto.Changeset.change(%{is_maintenance: true})
        |> Repo.update
    end
    case Repo.get(Status, 800) do
      nil -> nil
      item -> item
        |> Ecto.Changeset.change(%{is_maintenance: true})
        |> Repo.update
    end
  end
end
