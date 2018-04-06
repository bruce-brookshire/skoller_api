defmodule Skoller.Repo.Migrations.AddAutoUpdateStorage do
  use Ecto.Migration

  def change do
    alter table(:assignment_modifications) do
      add :is_auto_update, :boolean, default: false, null: false
    end
  end
end
