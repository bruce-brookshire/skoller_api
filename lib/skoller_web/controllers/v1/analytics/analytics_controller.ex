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


  @doc """
    Returns all classes that have at least one student enrolled or previously enrolled

    ## Returns:
    * 200
  """
  def communities(conn, _params) do
    class_communities = Skoller.Analytics.Classes.get_community_classes()

    conn
      |> put_status(:ok)
      |> render(AnalyticsView, "index-communities.json", communities: class_communities)
  end

end