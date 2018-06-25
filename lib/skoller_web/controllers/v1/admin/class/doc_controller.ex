defmodule SkollerWeb.Api.V1.Admin.Class.DocController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Class.Doc
  alias Skoller.Repo

  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  @change_req_role 400
  @help_req_role 500
  
  plug :verify_role, %{roles: [@admin_role, @change_req_role, @help_req_role]}

  def delete(conn, %{"id" => id}) do
    doc = Repo.get!(Doc, id)
    case Repo.delete(doc) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end