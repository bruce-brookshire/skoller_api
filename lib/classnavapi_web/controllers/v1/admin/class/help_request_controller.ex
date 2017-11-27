defmodule ClassnavapiWeb.Api.V1.Admin.Class.HelpRequestController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class.HelpRequest
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.HelpRequestView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def complete(conn, %{"id" => id}) do
    help_request_old = Repo.get!(HelpRequest, id)

    changeset = HelpRequest.changeset(help_request_old, %{is_completed: true})

    case Repo.update(changeset) do
      {:ok, help_request} ->
        render(conn, HelpRequestView, "show.json", help_request: help_request)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end