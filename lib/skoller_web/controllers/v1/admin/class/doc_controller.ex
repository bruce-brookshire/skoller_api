defmodule SkollerWeb.Api.V1.Admin.Class.DocController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.ClassDocs
  alias SkollerWeb.ChangesetView

  import SkollerWeb.Plugs.Auth

  @admin_role 200
  @change_req_role 400
  @help_req_role 500

  plug :verify_role, %{roles: [@admin_role, @change_req_role, @help_req_role]}

  def delete(conn, %{"id" => id}) do
    doc = ClassDocs.get_doc_by_id!(id)

    case ClassDocs.delete_doc(doc) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
