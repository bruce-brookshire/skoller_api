defmodule Skoller.Repo.Migrations.AddIsMaintenanceToStatus do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:class_statuses) do
      add :is_maintenance, :boolean, default: false, null: false
    end
  end
end
