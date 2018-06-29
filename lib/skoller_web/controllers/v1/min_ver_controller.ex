defmodule SkollerWeb.Api.V1.MinVerController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Settings
  alias SkollerWeb.Admin.SettingView

  def index(conn, _params) do
    settings = Settings.get_min_ver_settings()
    render(conn, SettingView, "index.json", settings: settings)
  end
end