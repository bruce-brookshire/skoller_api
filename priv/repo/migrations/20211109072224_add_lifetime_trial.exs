defmodule Skoller.Repo.Migrations.AddLifetimeTrial do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :lifetime_trial, :boolean, default: false
    end
  end

  def down do
    alter table(:users) do
      remove :lifetime_trial
    end
  end
end
