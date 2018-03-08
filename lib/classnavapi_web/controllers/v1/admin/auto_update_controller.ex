defmodule ClassnavapiWeb.Api.V1.Admin.AutoUpdateController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Admin.Settings
  alias ClassnavapiWeb.Admin.SettingView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    settings = Settings.get_auto_update_settings()
    render(conn, SettingView, "index.json", settings: settings)
  end

  def update(conn, %{"id" => id} = params) do
    settings_old = Settings.get_setting_by_name!(id)
    case Settings.update_setting(settings_old, params) do
      {:ok, setting} ->
        render(conn, SettingView, "show.json", setting: setting)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def forecast(conn, params) do
    
  end
end