defmodule ClassnavapiWeb.Api.V1.Class.StudentController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentClassView

  def create(conn, %{} = params) do

    changeset = StudentClass.changeset(%StudentClass{}, params)

    case Repo.insert(changeset) do
      {:ok, class} ->
        render(conn, StudentClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end