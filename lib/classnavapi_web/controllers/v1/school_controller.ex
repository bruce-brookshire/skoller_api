defmodule ClassnavapiWeb.Api.V1.SchoolController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.School
  alias Classnavapi.Repo
  alias ClassnavapiWeb.SchoolView

  def index(conn, _params) do
    schools = Repo.all(School)
    render(conn, SchoolView, "index.json", schools: schools)
  end
end