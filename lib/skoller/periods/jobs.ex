defmodule Skoller.Periods.Jobs do
  @moduledoc """
  A module for jobs dealing with class periods.
  """

  alias Skoller.Repo
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Periods
  
  import Ecto.Query

  @future_status 400
  @prompt_status 300
  @active_status 200
  @past_status 100

  @doc """
  This is a job that advances class period statuses based on their start and
  end date.
  """
  def evaluate_statuses(now) do
    now |> check_active_periods()
    now |> check_future_periods()
  end

  defp check_active_periods(now) do
    from(p in ClassPeriod)
    |> where([p], p.class_period_status_id in [@active_status, @prompt_status])
    |> where([p], p.end_date <= ^now)
    |> Repo.all()
    |> Enum.each(&Periods.update_period_status(&1, @past_status))

    #TODO datetime code here changed for bug fix
    # from(p in ClassPeriod)
    # |> where([p], p.class_period_status_id == @active_status)
    # |> where([p], p.end_date <= datetime_add(^now, 0, "day"))
    # |> where([p], p.is_main_period == true)
    # |> Repo.all()
    # |> Enum.each(&Periods.update_period_status(&1, @prompt_status))
  end

  defp check_future_periods(now) do
    from(p in ClassPeriod)
    |> where([p], p.class_period_status_id == @future_status)
    |> where([p], p.start_date < ^now)
    |> Repo.all()
    |> Enum.each(&Periods.update_period_status(&1, @active_status))
  end

  def update_all_period_statuses() do
    periods = from(p in ClassPeriod) |> Repo.all()
    Enum.each(periods, fn p ->
      Periods.reset_status(p)
    end)
  end
end