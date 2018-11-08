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

    alter table(:class_periods) do
      add :start_date, :utc_datetime
      add :end_date, :utc_datetime
    end
    flush()
    from(c in ClassPeriod)
    |> where([c], c.name == "Spring 2018")
    |> Repo.update_all(set: [start_date: spring_start, end_date: spring_end])
    flush()
    from(c in ClassPeriod)
    |> where([c], is_nil(c.start_date))
    |> Repo.update_all(set: [start_date: fall_start, end_date: fall_end])
  end
  
  def down do
    alter table(:class_periods) do
      remove :start_date
      remove :end_date
    end
  end
end
