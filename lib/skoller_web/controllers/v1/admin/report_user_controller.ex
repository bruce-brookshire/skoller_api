defmodule SkollerWeb.Api.V1.Admin.ReportUserController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Admin.Users
  alias SkollerWeb.ReportView

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def complete(conn, %{"id" => id}) do
    case Users.complete_report(id) do
      {:ok, report} ->
        render(conn, ReportView, "show.json", report: report)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, _params) do
    reports = Users.get_incomplete_reports()
    render(conn, ReportView, "index.json", reports: reports)
  end
end
