defmodule SkollerWeb.Api.V1.Analytics.AnalyticsController do
  @moduledoc false
  use SkollerWeb, :controller

  alias Skoller.Analytics
  alias SkollerWeb.AnalyticsView

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, params) do
    analytics = Analytics.get_analytics_summary(params)

    render(conn, AnalyticsView, "show.json", analytics: analytics)
  end
end