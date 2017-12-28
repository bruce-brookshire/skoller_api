defmodule ClassnavapiWeb.SchoolView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.SchoolView
  alias ClassnavapiWeb.School.EmailDomainView
  alias ClassnavapiWeb.PeriodView
  alias Classnavapi.Repo

  def render("index.json", %{schools: schools}) do
    render_many(schools, SchoolView, "school.json")
  end

  def render("show.json", %{school: school}) do
    render_one(school, SchoolView, "school.json")
  end

  def render("school.json", %{school: school}) do
    school = school |> Repo.preload([:email_domains, :class_periods])
    %{
      id: school.id,
      name: school.name,
      periods: active_periods(school.class_periods),
      is_diy_enabled: school.is_diy_enabled,
      is_diy_preferred: school.is_diy_preferred,
      is_auto_syllabus: school.is_auto_syllabus,
      email_domains: render_many(school.email_domains, EmailDomainView, "email_domain.json")
    }
  end

  defp active_periods(class_periods) do
    today = DateTime.utc_now()
    class_periods 
    |> Enum.filter(&DateTime.compare(&1.start_date, today) in [:lt, :eq] and DateTime.compare(&1.end_date, today) in [:gt, :eq])
    |> render_many(PeriodView, "period.json")
  end
end
