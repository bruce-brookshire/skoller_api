defmodule ClassnavapiWeb.Api.V1.ProfessorController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Professor
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ProfessorView

  def create(conn, %{} = params) do

    changeset = Professor.changeset_insert(%Professor{}, params)

    case Repo.insert(changeset) do
      {:ok, professor} ->
        render(conn, ProfessorView, "show.json", professor: professor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, _) do
    professors = Repo.all(Professor)
    render(conn, ProfessorView, "index.json", professors: professors)
  end

  def show(conn, %{"id" => id}) do
    professor = Repo.get!(Professor, id)
    render(conn, ProfessorView, "show.json", professor: professor)
  end

  def update(conn, %{"id" => id} = params) do
    professor_old = Repo.get!(Professor, id)
    changeset = Professor.changeset_update(professor_old, params)

    case Repo.update(changeset) do
      {:ok, professor} ->
        render(conn, ProfessorView, "show.json", professor: professor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end