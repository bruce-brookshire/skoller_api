defmodule ClassnavapiWeb.ProfessorView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.ProfessorView

  def render("index.json", %{professors: professors}) do
    render_many(professors, ProfessorView, "professor.json")
  end

  def render("show.json", %{professor: professor}) do
    render_one(professor, ProfessorView, "professor.json")
  end

  def render("professor.json", %{professor: professor}) do
    %{
        id: professor.id,
        name_first: professor.name_first,
        name_last: professor.name_last,
        email: professor.email,
        office_availability: professor.office_availability,
        office_location: professor.office_location,
        phone: professor.phone
    }
  end
end
