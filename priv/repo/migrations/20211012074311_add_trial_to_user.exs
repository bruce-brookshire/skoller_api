defmodule Skoller.Repo.Migrations.AddTrialToUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :trial_start, :utc_datetime
      add :trial_end, :utc_datetime
    end
  end

  def down do
    alter table(:users) do
      remove :trial_start
      remove :trial_end
    end
  end
end
