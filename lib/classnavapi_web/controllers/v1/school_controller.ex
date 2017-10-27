defmodule ClassnavapiWeb.Api.V1.SchoolController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.School
  alias Classnavapi.Repo
  alias ClassnavapiWeb.SchoolView

  def create(conn, %{} = params) do

    changeset = School.changeset_insert(%School{}, params)

    case Repo.insert(changeset) do
      {:ok, school} ->
        render(conn, SchoolView, "show.json", school: school)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, _) do
    schools = Repo.all(School)
    render(conn, SchoolView, "index.json", schools: schools)
  end

  def show(conn, %{"id" => id}) do
    school = Repo.get!(School, id)
    render(conn, SchoolView, "show.json", school: school)
  end

  def update(conn, %{"id" => id} = params) do
    school_old = Repo.get!(School, id)
    changeset = School.changeset_update(school_old, params)

    case Repo.update(changeset) do
      {:ok, school} ->
        render(conn, SchoolView, "show.json", school: school)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end