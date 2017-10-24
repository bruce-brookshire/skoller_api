defmodule ClassnavapiWeb.Api.V1.Class.DocController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class.Doc
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.DocView

  def create(conn, %{"file" => file, "class_id" => class_id} = params) do

    scope = Repo.get!(Classnavapi.Class, class_id)
    case Classnavapi.DocUpload.store({file, scope}) do
      {:ok, inserted} ->
        location = Classnavapi.DocUpload.url({inserted, scope})
      _ ->
        location = nil
    end

    changeset = Doc.changeset(%Doc{}, Map.put(params, "path", location))

    case Repo.insert(changeset) do
      {:ok, doc} ->
        render(conn, DocView, "show.json", doc: doc)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end