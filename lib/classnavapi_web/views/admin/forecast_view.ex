defmodule ClassnavapiWeb.Admin.ForecastView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Admin.ForecastView

  def render("show.json", %{forecast: forecast}) do
    render_one(forecast, ForecastView, "forecast.json")
  end

  def render("forecast.json", %{forecast: forecast}) do
    forecast
  end
end