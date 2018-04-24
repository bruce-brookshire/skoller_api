defmodule SkollerWeb.LocationView do
  use SkollerWeb, :view

  alias SkollerWeb.LocationView

  def render("index.json", %{locations: locations}) do
      render_many(locations, LocationView, "location.json")
  end

  def render("location.json", %{location: location}) do
    %{
        id: location.state_code,
        name: location.name
    }
  end
end
