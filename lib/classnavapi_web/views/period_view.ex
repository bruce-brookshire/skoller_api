defmodule ClassnavapiWeb.PeriodView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.PeriodView
  alias Classnavapi.Classes
  alias Classnavapi.Students

  def render("index.json", %{periods: periods}) do
    render_many(periods, PeriodView, "period.json")
  end

  def render("show.json", %{period: period}) do
    render_one(period, PeriodView, "period.json")
  end

  def render("period.json", %{period: period}) do
    %{
      id: period.id,
      name: period.name,
      inserted_at: period.inserted_at,
      class_count: Classes.get_class_count_by_period(period.id),
      student_count: Students.get_enrollment_by_period_id(period.id)
    }
  end
end
