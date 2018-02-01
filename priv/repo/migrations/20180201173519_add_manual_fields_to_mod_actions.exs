defmodule Classnavapi.Repo.Migrations.AddManualFieldsToModActions do
  use Ecto.Migration

  def change do
    alter table(:modification_actions) do
      add :is_manual, :boolean, default: false, null: false
    end
  end
end
