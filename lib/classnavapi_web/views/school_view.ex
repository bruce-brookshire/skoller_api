defmodule ClassnavapiWeb.SchoolView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.SchoolView

  def render("index.json", %{schools: schools}) do
    render_many(schools, SchoolView, "school.json")
  end

  def render("show.json", %{school: school}) do
    render_one(school, SchoolView, "school.json")
  end

  def render("school.json", %{school: school}) do
    %{name: school.name,
      adr_line_1: school.adr_line_1,
      adr_line_2: school.adr_line_2,
      adr_city: school.adr_city,
      adr_state: school.adr_state,
      adr_zip: school.adr_zip,
      timezone: school.timezone,
      email_domain: school.email_domain,
      email_domain_prof: school.email_domain_prof,
      is_active: school.is_active}
  end
end
