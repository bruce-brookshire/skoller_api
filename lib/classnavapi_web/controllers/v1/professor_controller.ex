defmodule ClassnavapiWeb.Api.V1.ProfessorController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Professor
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ProfessorView

  def create(conn, %{} = params) do

    changeset = Professor.changeset(%Professor{}, params)

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
end