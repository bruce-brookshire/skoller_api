defmodule Skoller.Repo.Migrations.AddTrialBooleanToUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :trial, :boolean, default: true
    end
  end

  def down do
    alter table(:users) do
      remove :trial
    end
  end
end
