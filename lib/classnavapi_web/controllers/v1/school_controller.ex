defmodule ClassnavapiWeb.Api.V1.SchoolController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Schools.School
  alias Classnavapi.Repo
  alias ClassnavapiWeb.SchoolView

  import Ecto.Query

  def index(conn, _params) do
    schools = from(school in School)
              |> Repo.all()
    render(conn, SchoolView, "index.json", schools: schools)
  end
end