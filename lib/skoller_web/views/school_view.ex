defmodule SkollerWeb.SchoolView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.SchoolView
  alias SkollerWeb.PeriodView
  alias Skoller.Repo

  def render("index.json", %{schools: schools}) do
    render_many(schools, SchoolView, "school.json")
  end

  def render("show.json", %{school: school}) do
    render_one(school, SchoolView, "school.json")
  end
  
  def render("school.json", %{school: school}) do
    school = school |> Repo.preload([:class_periods])
    %{
      id: school.id,
      name: school.name,
      periods: render_many(school.class_periods, PeriodView, "period.json"),
      timezone: school.timezone,
      adr_region: school.adr_region,
      adr_locality: school.adr_locality,
      is_university: school.is_university,
      color: school.color,
      is_syllabus_overload: school.is_syllabus_overload
    }
  end
end
