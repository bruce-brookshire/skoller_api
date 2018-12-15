defmodule Skoller.Repo.Migrations.CreateClassPeriodGenerators do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.Periods.Generator

  def change do
    create table(:class_period_generators) do
      add :start_month, :integer
      add :start_day, :integer
      add :end_month, :integer
      add :end_day, :integer
      add :name_prefix, :string
      add :is_main_period, :boolean, default: false, null: false

      timestamps()
    end
    flush()
    Repo.insert!(%Generator{start_month: 1, end_month: 5, start_day: 15, end_day: 15, name_prefix: "Spring", is_main_period: true})
    Repo.insert!(%Generator{start_month: 8, end_month: 12, start_day: 15, end_day: 15, name_prefix: "Fall", is_main_period: true})
    Repo.insert!(%Generator{start_month: 5, end_month: 8, start_day: 15, end_day: 1, name_prefix: "Summer", is_main_period: false})
  end
end
