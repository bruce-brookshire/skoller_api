defmodule SkollerWeb.Api.V1.Class.DocController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Class.DocView
  alias SkollerWeb.ChangesetView
  alias Skoller.ClassDocs

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300

  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role]}
  plug :verify_member, :class

  def create(%{assigns: %{user: user}} = conn, %{"file" => file, "class_id" => class_id} = params) do
    case ClassDocs.upload_doc(file, user.id, class_id, Map.get(params, "is_syllabus", false),
           sammi: true
         ) do
      {:ok, %{doc: doc}} ->
        conn
        |> put_view(DocView)
        |> render("show.json", doc: doc)

      {:error, _, failed_value, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ChangesetView)
        |> render("error.json", changeset: failed_value)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    docs = ClassDocs.get_docs_by_class(class_id)

    conn
    |> put_view(DocView)
    |> render("index.json", docs: docs)
  end
end
