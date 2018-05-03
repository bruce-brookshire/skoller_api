defmodule Skoller.Repo.Migrations.AddIsMaintenanceToStatus do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.Classes.Status

  def change do
    alter table(:class_statuses) do
      add :is_maintenance, :boolean, default: false, null: false
    end
    flush()
    Repo.get!(Status, 600)
    |> Ecto.Changeset.change(%{is_maintenance: true})
    |> Repo.update!
    Repo.get!(Status, 800)
    |> Ecto.Changeset.change(%{is_maintenance: true})
    |> Repo.update!
  end
end
