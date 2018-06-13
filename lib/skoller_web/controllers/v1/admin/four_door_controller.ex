defmodule SkollerWeb.Api.V1.Admin.FourDoorController do
  use SkollerWeb, :controller

  alias Skoller.FourDoor
  alias SkollerWeb.Admin.SchoolView
  alias SkollerWeb.AllView

  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    fd = FourDoor.get_default_four_door()
    render(conn, AllView, "show.json", all: fd)
  end
end