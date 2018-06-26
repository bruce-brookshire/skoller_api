defmodule SkollerWeb.Api.V1.Admin.MinVerController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Admin.Settings
  alias SkollerWeb.Admin.SettingView
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Repo

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def update(conn, %{"settings" => settings}) do
    multi = Ecto.Multi.new()
    |> Ecto.Multi.run(:settings, &update_settings(settings, &1))
   
    case Repo.transaction(multi) do
      {:ok, _map} ->
        settings = Settings.get_min_ver_settings()
        render(conn, SettingView, "index.json", settings: settings)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp update_settings(settings, _) do
    status = settings |> Enum.map(&update_setting(&1))
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp update_setting(%{"name" => name} = params) do
    settings_old = Settings.get_setting_by_name!(name)
    Settings.update_setting(settings_old, params)
  end
end