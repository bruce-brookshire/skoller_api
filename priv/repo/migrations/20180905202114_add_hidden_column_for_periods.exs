defmodule Skoller.Repo.Migrations.AddHiddenColumnForPeriods do
  use Ecto.Migration

  def change do
    alter table(:class_periods) do
      add :is_hidden, :boolean, default: false, null: false
    end
  end
end
