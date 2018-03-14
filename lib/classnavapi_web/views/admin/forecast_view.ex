defmodule ClassnavapiWeb.Admin.ForecastView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Admin.ForecastView
  alias ClassnavapiWeb.Admin.SettingView

  def render("show.json", %{forecast: forecast}) do
    render_one(forecast, ForecastView, "forecast.json")
  end

  def render("forecast.json", %{forecast: %{metrics: metrics, people: people, settings: settings}}) do
    %{
      metrics: metrics,
      people: people,
      settings: render_many(settings, SettingView, "setting.json")
    }
  end

  def render("forecast.json", %{forecast: forecast}) do
    forecast
  end
end