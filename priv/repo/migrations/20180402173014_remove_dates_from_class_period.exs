defmodule Classnavapi.Repo.Migrations.RemoveDatesFromClassPeriod do
  use Ecto.Migration

  def up do
    alter table(:class_periods) do
      remove :start_date
      remove :end_date
    end
  end

  def down do
    alter table(:class_periods) do
      add :start_date, :date
      add :end_date, :date
    end
  end
end
