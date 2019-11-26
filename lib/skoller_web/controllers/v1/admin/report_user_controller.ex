defmodule SkollerWeb.Api.V1.Admin.ReportUserController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.UserReports
  alias SkollerWeb.ReportView

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def complete(conn, %{"id" => id}) do
    case UserReports.complete_report(id) do
      {:ok, report} ->
        conn
        |> put_view(ReportView)
        |> render("show.json", report: report)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def index(conn, _params) do
    reports = UserReports.get_incomplete_reports()

    conn
    |> put_view(ReportView)
    |> render("index.json", reports: reports)
  end
end
