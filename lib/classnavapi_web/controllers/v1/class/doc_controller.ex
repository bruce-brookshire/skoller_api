defmodule ClassnavapiWeb.Api.V1.Class.DocController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class
  alias Classnavapi.Class.Doc
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.DocView
  alias ClassnavapiWeb.ChangesetView
  alias ClassnavapiWeb.Helpers.StatusHelper
  alias ClassnavapiWeb.Helpers.ClassDocUpload
  alias ClassnavapiWeb.Sammi

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role]}
  plug :verify_member, :class

  def create(%{assigns: %{user: user}} = conn, %{"file" => file, "class_id" => class_id} = params) do

    location = ClassDocUpload.upload_class_doc(file)

    Task.start(Sammi, :sammi, [params, location])
  
    params = params 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)
    |> Map.put("user_id", user.id)

    changeset = Doc.changeset(%Doc{}, params)

    class = Repo.get!(Class, class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:doc, changeset)
    |> Ecto.Multi.run(:status, &StatusHelper.check_status(class, &1))

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