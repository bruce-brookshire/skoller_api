defmodule ClassnavapiWeb.SchoolView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.SchoolView

  def render("index.json", %{schools: schools}) do
    render_many(schools, SchoolView, "school.json")
  end

  def render("show.json", %{school: school}) do
    render_one(school, SchoolView, "school_detail.json")
  end

  def render("school.json", %{school: school}) do
    %{id: school.id,
      name: school.name,
      adr_line_1: school.adr_line_1,
      adr_line_2: school.adr_line_2,
      adr_city: school.adr_city,
      adr_state: school.adr_state,
      adr_zip: school.adr_zip,
      timezone: school.timezone,
      is_active: school.is_active,
      is_editable: school.is_editable}
  end

  def render("school_detail.json", %{school: school}) do
    school = Classnavapi.Repo.preload(school, :email_domains)
    render_one(school, SchoolView, "school.json")
    |> Map.merge(
      %{
        email_domain: render_many(school.email_domains, ClassnavapiWeb.School.EmailDomainView, "email_domain.json")
      }
    )
  end
end
