defmodule SkollerWeb.Api.V1.Admin.Class.HelpRequestController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.HelpRequests
  alias SkollerWeb.Class.HelpRequestView
  alias SkollerWeb.ChangesetView

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  @help_request_role 500
  
  plug :verify_role, %{roles: [@admin_role, @help_request_role]}

  def complete(conn, %{"id" => id}) do
    case HelpRequests.complete(id) do
      {:ok, help_request} ->
        render(conn, HelpRequestView, "show.json", help_request: help_request)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end
end