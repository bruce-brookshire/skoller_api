defmodule Skoller.Repo.Migrations.AddTimeToPeriods do
  use Ecto.Migration

  def up do

    alter table(:class_periods) do
      modify :start_date, :utc_datetime
      modify :end_date, :utc_datetime
    end


  end

  def down do
    alter table(:class_periods) do
      modify :start_date, :date
      modify :end_date, :date
    end

  end
end
