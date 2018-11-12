defmodule SkollerWeb.PeriodView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.PeriodView
  alias Skoller.Classes.Periods
  alias Skoller.EnrolledStudents.ClassPeriods
  alias SkollerWeb.Period.StatusView
  alias Skoller.Repo

  def render("index.json", %{periods: periods}) do
    render_many(periods, PeriodView, "period.json")
  end

  def render("show.json", %{period: period}) do
    render_one(period, PeriodView, "period.json")
  end

  def render("period.json", %{period: period}) do
    period = period |> Repo.preload(:class_period_status)
    %{
      id: period.id,
      name: period.name,
      start_date: period.start_date,
      end_date: period.end_date,
      class_period_status: render_one(period.class_period_status, StatusView, "status.json"),
      inserted_at: period.inserted_at,
      class_count: Periods.get_class_count_by_period(period.id),
      student_count: ClassPeriods.get_enrollment_by_period_id(period.id),
      is_main_period: period.is_main_period
    }
  end
end
