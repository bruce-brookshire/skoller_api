defmodule SkollerWeb.Api.V1.Admin.SettingsController do
  use SkollerWeb, :controller

  alias Skoller.Settings
  alias SkollerWeb.Admin.SettingView

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def show(conn, %{"name" => name}) do
    setting = Settings.get_setting_by_name!(name)

    conn
    |> put_view(SettingView)
    |> render("show.json", setting: setting)
  end

  def update(conn, %{"name" => name, "value" => value} = params)
      when not (is_nil(name) or is_nil(value)) do
    case Settings.update_setting(params) do
      {:ok, setting} ->
        conn
        |> put_view(SettingView)
        |> render("show.json", setting: setting)

      _ ->
        send_resp(conn, 422, "Issue updating setting")
    end
  end
end
