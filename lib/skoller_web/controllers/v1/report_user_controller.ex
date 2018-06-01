defmodule SkollerWeb.Api.V1.ReportUserController do
  use SkollerWeb, :controller

  alias Skoller.Users

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}

  def create(conn, params) do
    case Users.report_user(params) do
      {:ok, _} ->
        conn |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
