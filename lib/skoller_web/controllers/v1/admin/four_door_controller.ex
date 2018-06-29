defmodule SkollerWeb.Api.V1.Admin.FourDoorController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.FourDoor
  alias SkollerWeb.AllView
  alias SkollerWeb.Responses.MultiError

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    fd = FourDoor.get_default_four_door()
    render(conn, AllView, "show.json", all: fd)
  end

  def update(conn, params) do
    case FourDoor.update_four_door_defaults(params) do
      {:ok, _params} ->
        fd = FourDoor.get_default_four_door()
        render(conn, AllView, "show.json", all: fd)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end