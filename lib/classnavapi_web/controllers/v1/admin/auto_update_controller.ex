defmodule ClassnavapiWeb.Api.V1.Admin.AutoUpdateController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Admin.Settings
  alias ClassnavapiWeb.Admin.SettingView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def index(conn, params) do
    settings = Settings.get_auto_update_settings()
    render(conn, SettingView, "index.json", settings: settings)
  end

  def update(conn, params) do
    
  end

  def forecast(conn, params) do
    
  end
end