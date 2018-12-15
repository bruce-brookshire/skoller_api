defmodule SkollerWeb.Api.V1.Admin.AutoUpdateController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Settings
  alias SkollerWeb.Admin.SettingView
  alias SkollerWeb.Admin.ForecastView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.AutoUpdates

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    metrics = Settings.get_auto_update_settings()
    |> AutoUpdates.get_auto_update_metrics()

    render(conn, ForecastView, "show.json", forecast: metrics)
  end

  def update(conn, %{"settings" => settings}) do
    case Settings.update_settings(settings) do
      {:ok, _params} ->
        AutoUpdates.process_auto_updates_all_mods()
        settings = Settings.get_auto_update_settings()
        render(conn, SettingView, "index.json", settings: settings)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  # TODO: Get this by pattern matching. Can reduce routes.
  def forecast(conn, params) do
    metrics = params
    |> AutoUpdates.get_settings_from_params_or_default()
    |> AutoUpdates.get_auto_update_metrics()

    render(conn, ForecastView, "show.json", forecast: metrics)
  end
end