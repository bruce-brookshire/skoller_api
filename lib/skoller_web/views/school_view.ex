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
    render_one(school, SchoolView, "school-detail.json")
  end

  def render("school-detail.json", %{school: school}) do
    school = school |> Repo.preload([:class_periods])
    %{
      id: school.id,
      name: school.name,
      periods: render_many(school.class_periods, PeriodView, "period.json"),
      is_diy_enabled: school.is_diy_enabled,
      is_diy_preferred: school.is_diy_preferred,
      is_auto_syllabus: school.is_auto_syllabus,
      timezone: school.timezone,
      adr_region: school.adr_region,
      adr_locality: school.adr_locality,
      is_university: school.is_university,
      color: school.color
    }
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
      color: school.color
    }
  end
end
