defmodule SkollerWeb.Api.V1.Admin.MinVerController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Settings
  alias SkollerWeb.Admin.SettingView
  alias SkollerWeb.Responses.MultiError

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def update(conn, %{"settings" => settings}) do
    case Settings.update_settings(settings) do
      {:ok, _map} ->
        settings = Settings.get_min_ver_settings()
        render(conn, SettingView, "index.json", settings: settings)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end