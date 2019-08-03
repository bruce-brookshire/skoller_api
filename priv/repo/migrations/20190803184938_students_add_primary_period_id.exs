defmodule Skoller.Repo.Migrations.StudentsAddPrimaryPeriodId do
  use Ecto.Migration

  def up do
    alter table(:students) do
      add(:primary_period_id, references(:class_periods, on_delete: :nothing))
    end
  end

  def down do
    alter table(:students) do
      remove(:primary_period_id)
    end
  end
end
