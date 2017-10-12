defmodule ClassnavapiWeb.Api.V1.SchoolController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.School
  alias Classnavapi.Repo
  alias ClassnavapiWeb.SchoolView

  def create(conn, %{} = params) do

    changeset = School.changeset(%School{}, params)

    case Repo.insert(changeset) do
      {:ok, school} ->
        render(conn, SchoolView, "show.json", school: school)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end