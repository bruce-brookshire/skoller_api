defmodule ClassnavapiWeb.Api.V1.MinVerController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Admin.Settings
  alias ClassnavapiWeb.Admin.SettingView

  def index(conn, _params) do
    settings = Settings.get_min_ver_settings()
    render(conn, SettingView, "index.json", settings: settings)
  end
end