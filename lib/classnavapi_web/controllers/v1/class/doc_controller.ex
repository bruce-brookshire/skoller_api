defmodule ClassnavapiWeb.Api.V1.Class.DocController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Doc
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.DocView
  alias Classnavapi.DocUpload
  alias ClassnavapiWeb.ChangesetView
  alias Ecto.UUID

  import Ecto.Query

  def create(conn, %{"file" => file} = params) do

    scope = %{"id" => UUID.generate()}
    location = 
      case DocUpload.store({file, scope}) do
        {:ok, inserted} ->
          DocUpload.url({inserted, scope})
        _ ->
          nil
      end

    changeset = Doc.changeset(%Doc{}, Map.put(params, "path", location))

    case Repo.insert(changeset) do
      {:ok, doc} ->
        render(conn, DocView, "show.json", doc: doc)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    docs = Repo.all(from docs in Doc, where: docs.class_id == ^class_id)
    render(conn, DocView, "index.json", docs: docs)
  end
end