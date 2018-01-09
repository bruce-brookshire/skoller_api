defmodule ClassnavapiWeb.Api.V1.Class.DocController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class
  alias Classnavapi.Class.Doc
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.DocView
  alias Classnavapi.DocUpload
  alias ClassnavapiWeb.ChangesetView
  alias Ecto.UUID
  alias ClassnavapiWeb.Helpers.StatusHelper
  alias ClassnavapiWeb.Sammi

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role]}
  plug :verify_member, :class

  def create(conn, %{"file" => file, "class_id" => class_id} = params) do

    scope = %{"id" => UUID.generate()}
    location = 
      case DocUpload.store({file, scope}) do
        {:ok, inserted} ->
          DocUpload.url({inserted, scope})
        {:error, error} ->
          require Logger
          Logger.info(inspect(error))
          nil
      end

    Task.start(Sammi, :sammi, [params, location])
  
    params = params 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)

    changeset = Doc.changeset(%Doc{}, params)

    class = Repo.get!(Class, class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:doc, changeset)
    |> Ecto.Multi.run(:status, &StatusHelper.check_status(&1, class))

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

  def delete(conn, %{"id" => id}) do
    doc = Repo.get!(Doc, id)
    case Repo.delete(doc) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end