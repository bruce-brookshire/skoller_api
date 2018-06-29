defmodule SkollerWeb.Admin.ForecastView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Admin.ForecastView
  alias SkollerWeb.Admin.SettingView

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