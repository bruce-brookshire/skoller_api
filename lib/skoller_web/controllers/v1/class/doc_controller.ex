defmodule SkollerWeb.Api.V1.Class.DocController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.ClassDocs.Doc
  alias Skoller.Repo
  alias SkollerWeb.Class.DocView
  alias SkollerWeb.ChangesetView
  alias Skoller.ClassDocs
  alias Skoller.Sammi
  alias Skoller.Classes

  import Ecto.Query
  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role]}
  plug :verify_member, :class

  def create(%{assigns: %{user: user}} = conn, %{"file" => file, "class_id" => class_id} = params) do

    location = ClassDocs.upload_class_doc(file)

    Task.start(Sammi, :sammi, [params, location])
  
    params = params 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)
    |> Map.put("user_id", user.id)

    changeset = Doc.changeset(%Doc{}, params)

    class = Classes.get_class_by_id!(class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:doc, changeset)
    |> Ecto.Multi.run(:status, &Classes.check_status(class, &1))

    case Repo.transaction(multi) do
      {:ok, %{doc: doc}} ->
        render(conn, DocView, "show.json", doc: doc)
      {:error, _, failed_value, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: failed_value)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    docs = Repo.all(from docs in Doc, where: docs.class_id == ^class_id)
    render(conn, DocView, "index.json", docs: docs)
  end
end