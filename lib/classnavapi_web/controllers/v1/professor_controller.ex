defmodule ClassnavapiWeb.Api.V1.ProfessorController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Professor
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ProfessorView

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@admin_role, @student_role]}

  def create(conn, %{"period_id" => class_period_id} = params) do
    params = params |> Map.put("class_period_id", class_period_id)

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

  def index(conn, %{"period_id" => class_period_id}) do
    professors = Repo.all(from p in Professor, where: p.class_period_id == ^class_period_id)
    render(conn, ProfessorView, "index.json", professors: professors)
  end

  def show(conn, %{"id" => id}) do
    professor = Repo.get!(Professor, id)
    render(conn, ProfessorView, "show.json", professor: professor)
  end
end