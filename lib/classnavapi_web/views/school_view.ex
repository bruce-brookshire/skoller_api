defmodule ClassnavapiWeb.SchoolView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.SchoolView
  alias ClassnavapiWeb.School.EmailDomainView
  alias Classnavapi.Repo

  def render("index.json", %{schools: schools}) do
    render_many(schools, SchoolView, "school.json")
  end

  def render("show.json", %{school: school}) do
    render_one(school, SchoolView, "school.json")
  end

  def render("school.json", %{school: school}) do
    school = school |> Repo.preload(:email_domains)
    %{
      id: school.id,
      name: school.name,
      email_domains: render_many(school.email_domains, EmailDomainView, "email_domain.json")
    }
  end
end
