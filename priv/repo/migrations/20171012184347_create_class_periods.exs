defmodule Skoller.Repo.Migrations.CreateClassPeriods do
  use Ecto.Migration

  def change do
    create table(:class_periods) do
      add :name, :string
      add :start_date, :date
      add :end_date, :date
      add :school_id, references(:schools, on_delete: :nothing)

      timestamps()
    end

    create index(:class_periods, [:school_id])
  end
end
