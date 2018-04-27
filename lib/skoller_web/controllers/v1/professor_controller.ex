defmodule SkollerWeb.Api.V1.ProfessorController do
  use SkollerWeb, :controller

  alias Skoller.Professors
  alias SkollerWeb.ProfessorView

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@admin_role, @student_role]}

  def create(conn, params) do
    case Professors.create_professor(params) do
      {:ok, professor} ->
        render(conn, ProfessorView, "show.json", professor: professor)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"school_id" => school_id} = params) do
    professors = Professors.get_professors(school_id, params)
    render(conn, ProfessorView, "index.json", professors: professors)
  end

  def show(conn, %{"id" => id}) do
    professor = Professors.get_professor_by_id!(id)
    render(conn, ProfessorView, "show.json", professor: professor)
  end
end