defmodule SkollerWeb.Api.V1.Admin.ReportUserController do
  use SkollerWeb, :controller

  alias Skoller.Admin.Users
  alias SkollerWeb.ReportView

  import SkollerWeb.Helpers.AuthPlug
  
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
end
