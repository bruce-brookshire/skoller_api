defmodule SkollerWeb.Admin.SchoolView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Admin.SchoolView
  alias SkollerWeb.PeriodView
  alias Skoller.Repo

  def render("index.json", %{schools: schools}) do
    render_many(schools, SchoolView, "school.json")
  end

  def render("show.json", %{school: school}) do
    render_one(school, SchoolView, "school.json")
  end

  def render("school.json", %{school: %{school: school, students: students, classes: classes}}) do
    school
    |> base_school_view()
    |> Map.put(:enrollment, floor_enrollment(students))
    |> Map.put(:classes, classes)
  end

  def render("school.json", %{school: school}) do
    base_school_view(school)
  end

  defp base_school_view(school) do
    school = school |> Repo.preload(:class_periods)

    %{
      id: school.id,
      name: school.name,
      adr_country: school.adr_country,
      adr_line_1: school.adr_line_1,
      adr_line_2: school.adr_line_2,
      adr_line_3: school.adr_line_3,
      adr_locality: school.adr_locality,
      adr_region: school.adr_region,
      adr_zip: school.adr_zip,
      timezone: school.timezone,
      is_readonly: school.is_readonly,
      is_university: school.is_university,
      short_name: school.short_name,
      class_periods: render_many(school.class_periods, PeriodView, "period.json"),
      is_chat_enabled: school.is_chat_enabled,
      is_assignment_posts_enabled: school.is_assignment_posts_enabled,
      color: school.color,
      is_syllabus_overload: school.is_syllabus_overload
    }
  end

  defp floor_enrollment(nil), do: 0
  defp floor_enrollment(num), do: num
end
