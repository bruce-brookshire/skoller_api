defmodule Skoller.Repo.Migrations.AddDatesToPeriods do
  @moduledoc false
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.Periods.ClassPeriod

  import Ecto.Query

  def up do
    {:ok, spring_start} = Date.new(2018, 1, 15)
    spring_start = spring_start |> Timex.to_datetime("America/Chicago") |> Timex.to_datetime

    {:ok, spring_end} = Date.new(2018, 5, 15)
    spring_end = spring_end |> Timex.to_datetime("America/Chicago") |> Timex.to_datetime

    {:ok, fall_start} = Date.new(2018, 8, 15)
    fall_start = fall_start |> Timex.to_datetime("America/Chicago") |> Timex.to_datetime

    {:ok, fall_end} = Date.new(2018, 12, 15)
    fall_end = fall_end |> Timex.to_datetime("America/Chicago") |> Timex.to_datetime

    now = DateTime.utc_now()

    create table(:class_period_statuses) do
      add :name, :string

      timestamps()
    end

    flush()
    Skoller.Repo.insert!(%Skoller.Periods.Status{id: 100, name: "Past"})
    Skoller.Repo.insert!(%Skoller.Periods.Status{id: 200, name: "Active"})
    Skoller.Repo.insert!(%Skoller.Periods.Status{id: 300, name: "Prompt"})
    Skoller.Repo.insert!(%Skoller.Periods.Status{id: 400, name: "Future"})
    flush()

    alter table(:class_periods) do
      add :start_date, :utc_datetime
      add :end_date, :utc_datetime
      add :class_period_status_id, references(:class_period_statuses, on_delete: :nothing)
      add :is_main_period, :boolean, default: false, nullable: false
    end

    create index(:class_periods, [:class_period_status_id])

    flush()

    from(c in ClassPeriod)
    |> where([c], c.name == "Spring 2018")
    |> Repo.update_all(set: [start_date: spring_start, end_date: spring_end, is_main_period: true])
    flush()
    from(c in ClassPeriod)
    |> where([c], is_nil(c.start_date))
    |> Repo.update_all(set: [start_date: fall_start, end_date: fall_end, is_main_period: true])
    flush()
    from(c in ClassPeriod)
    |> where([c], c.end_date < ^now)
    |> Repo.update_all(set: [class_period_status_id: 100])
    flush()
    from(c in ClassPeriod)
    |> where([c], is_nil(c.class_period_status_id))
    |> where([c], c.start_date > ^now)
    |> Repo.update_all(set: [class_period_status_id: 400])
    from(c in ClassPeriod)
    |> where([c], is_nil(c.class_period_status_id))
    |> where([c], c.end_date <= datetime_add(^now, 30, "day"))
    |> Repo.update_all(set: [class_period_status_id: 300])
    from(c in ClassPeriod)
    |> where([c], is_nil(c.class_period_status_id))
    |> Repo.update_all(set: [class_period_status_id: 200])
  end
  
  def down do
    alter table(:class_periods) do
      remove :start_date
      remove :end_date
      remove :class_period_status_id
      remove :is_main_period
    end
    drop table(:class_period_statuses)
  end
end
