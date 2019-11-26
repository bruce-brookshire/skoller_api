defmodule SkollerWeb.Api.V1.LocationController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Locations
  alias SkollerWeb.LocationView

  def index(conn, _params) do
    locations = Locations.get_states()

    conn
    |> put_view(LocationView)
    |> render("index.json", locations: locations)
  end
end
