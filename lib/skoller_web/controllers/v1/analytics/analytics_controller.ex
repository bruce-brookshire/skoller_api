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

  def communities_csv(conn, _params) do
    class_communities = Skoller.Analytics.Classes.get_community_classes()

    filename = get_filename()

    conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[attachment; filename="#{filename}"; filename*="#{filename}"])
      |> send_resp(200, communities_csv_parser(class_communities))
  end

  defp get_filename() do
    now = DateTime.utc_now
    "Class-Communities-#{now.month}_#{now.day}_#{now.year}_#{now.hour}_#{now.minute}_#{now.second}.csv"
  end

  defp communities_csv_parser(communities) do
    communities
      |> Enum.map(&get_row_data(&1))
      |> CSV.encode
      |> Enum.to_list
      |> add_headers
      |> to_string
  end

  defp add_headers(list) do
    [
      "Created on,Student Created,Term Name,Term Status,Class Name,Class Status,Active Count,Inactive Count,School Name\r\n"
      | list
    ]
  end

  defp get_row_data(community) do
    [
      community.created_on |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_string(), 
      community.is_student_created, 
      community.term_name, 
      community.term_status, 
      community.class_name, 
      community.class_status, 
      community.active, 
      community.inactive, 
      community.school_name
    ]
  end

end