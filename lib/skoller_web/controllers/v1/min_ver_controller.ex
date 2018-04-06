defmodule SkollerWeb.Api.V1.MinVerController do
  use SkollerWeb, :controller

  alias Skoller.Admin.Settings
  alias SkollerWeb.Admin.SettingView

  def index(conn, _params) do
    settings = Settings.get_min_ver_settings()
    render(conn, SettingView, "index.json", settings: settings)
  end
end