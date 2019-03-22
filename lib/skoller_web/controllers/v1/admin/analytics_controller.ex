defmodule SkollerWeb.Api.V1.Admin.AnalyticsController do
  @moduledoc false
  use SkollerWeb, :controller

  alias Skoller.Analytics
  alias Skoller.Analytics.Documents
  alias SkollerWeb.AnalyticsView

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, params) do
    analytics = Analytics.get_analytics_summary(params)

    render(conn, AnalyticsView, "show.json", analytics: analytics)
  end

  def schools_csv(conn, _params) do
    Documents.get_current_school_csv_path()
      |> IO.inspect
      |> csv(conn)
  end

  def users_csv(conn, _params) do
    Documents.get_current_user_csv_path()
      |> IO.inspect
      |> csv(conn)
  end

  def classes_csv(conn, _params) do
    Documents.get_current_class_csv_path()
      |> IO.inspect
      |> csv(conn)
  end

  defp csv(path, conn) do
    case HTTPoison.get(path) do
      {:ok, %{status_code: 200, body: body}} -> 
        IO.inspect body
        conn
          |> put_resp_content_type("text/csv")
          |> put_resp_header("content-disposition", ~s[attachment; filename="analytics.csv"; filename*="analytics.csv"])
          |> send_resp(200, body)
      _ -> conn |> send_resp(404, "csv not found")
    end
  end

end