defmodule SkollerWeb.Api.V1.SchoolController do
  use SkollerWeb, :controller

  alias SkollerWeb.SchoolView
  alias Skoller.Schools

  def index(conn, params) do
    schools = Schools.get_schools(params)
    render(conn, SchoolView, "index.json", schools: schools)
  end
end