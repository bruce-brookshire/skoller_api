defmodule SkollerWeb.Api.V1.Admin.Class.HelpRequestController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Class.HelpRequest
  alias Skoller.Repo
  alias SkollerWeb.Class.HelpRequestView

  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  @help_request_role 500
  
  plug :verify_role, %{roles: [@admin_role, @help_request_role]}

  def complete(conn, %{"id" => id}) do
    help_request_old = Repo.get!(HelpRequest, id)

    changeset = HelpRequest.changeset(help_request_old, %{is_completed: true})

    case Repo.update(changeset) do
      {:ok, help_request} ->
        render(conn, HelpRequestView, "show.json", help_request: help_request)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end