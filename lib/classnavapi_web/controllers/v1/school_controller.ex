defmodule ClassnavapiWeb.Api.V1.SchoolController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.School
  alias Classnavapi.Repo
  alias ClassnavapiWeb.SchoolView

  def index(conn, _) do
    schools = Repo.all(School)
    render(conn, SchoolView, "index.json", schools: schools)
  end

  def show(conn, %{"id" => id}) do
    school = Repo.get!(School, id)
    render(conn, SchoolView, "show.json", school: school)
  end
end