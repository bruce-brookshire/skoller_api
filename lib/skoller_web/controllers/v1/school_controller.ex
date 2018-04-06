defmodule SkollerWeb.Api.V1.SchoolController do
  use SkollerWeb, :controller

  alias Skoller.Schools.School
  alias Skoller.Repo
  alias SkollerWeb.SchoolView

  import Ecto.Query

  def index(conn, _params) do
    schools = from(school in School)
              |> Repo.all()
    render(conn, SchoolView, "index.json", schools: schools)
  end
end