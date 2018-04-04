defmodule ClassnavapiWeb.Admin.SchoolView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Admin.SchoolView
  alias ClassnavapiWeb.PeriodView
  alias Classnavapi.Repo

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
    school
    |> base_school_view()
  end

  defp base_school_view(school) do
    school = school |> Repo.preload(:class_periods)
    %{
      id: school.id,
      name: school.name,
      adr_line_1: school.adr_line_1,
      adr_line_2: school.adr_line_2,
      adr_city: school.adr_city,
      adr_state: school.adr_state,
      adr_zip: school.adr_zip,
      timezone: school.timezone,
      is_active_enrollment: school.is_active_enrollment,
      is_readonly: school.is_readonly,
      is_diy_enabled: school.is_diy_enabled,
      is_diy_preferred: school.is_diy_preferred,
      is_auto_syllabus: school.is_auto_syllabus,
      short_name: school.short_name,
      class_periods: render_many(school.class_periods, PeriodView, "period.json"),
      is_chat_enabled: school.is_chat_enabled,
      is_assignment_posts_enabled: school.is_assignment_posts_enabled
    }
  end

  defp floor_enrollment(nil), do: 0
  defp floor_enrollment(num), do: num
end
