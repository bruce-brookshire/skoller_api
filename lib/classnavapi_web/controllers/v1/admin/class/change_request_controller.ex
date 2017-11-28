defmodule ClassnavapiWeb.Api.V1.Admin.Class.ChangeRequestController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class.ChangeRequest
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.ChangeRequestView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  @change_req_role 400
  
  plug :verify_role, %{roles: [@change_req_role, @admin_role]}

  def complete(conn, %{"id" => id}) do
    change_request_old = Repo.get!(ChangeRequest, id)

    changeset = ChangeRequest.changeset(change_request_old, %{is_completed: true})

    case Repo.update(changeset) do
      {:ok, change_request} ->
        render(conn, ChangeRequestView, "show.json", change_request: change_request)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end