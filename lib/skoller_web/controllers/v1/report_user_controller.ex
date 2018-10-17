defmodule SkollerWeb.Api.V1.ReportUserController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.UserReports

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}

  def create(conn, params) do
    params = params |> Map.put("reported_by", conn.assigns[:user].id)
    case UserReports.report_user(params) do
      {:ok, _} ->
        conn |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
