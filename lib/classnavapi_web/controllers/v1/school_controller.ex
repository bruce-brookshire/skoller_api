defmodule ClassnavapiWeb.Api.V1.SchoolController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.School
  alias Classnavapi.Repo
  alias ClassnavapiWeb.SchoolView

  import Ecto.Query

  def index(conn, _params) do
    schools = from(school in School)
              |> where([school], school.is_active_enrollment == true) 
              |> Repo.all()
    render(conn, SchoolView, "index.json", schools: schools)
  end
end