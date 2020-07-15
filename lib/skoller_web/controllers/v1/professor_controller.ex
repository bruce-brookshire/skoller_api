defmodule SkollerWeb.Api.V1.ProfessorController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Professors
  alias SkollerWeb.ProfessorView

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200
  @insights_role 700

  plug :verify_role, %{roles: [@admin_role, @student_role, @insights_role]}

  def create(conn, params) do
    case Professors.create_professor(params) do
      {:ok, professor} ->
        conn
        |> put_view(ProfessorView)
        |> render("show.json", professor: professor)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def index(conn, %{"school_id" => school_id} = params) do
    professors = Professors.get_professors(school_id, params)

    conn
    |> put_view(ProfessorView)
    |> render("index.json", professors: professors)
  end

  def show(conn, %{"id" => id}) do
    professor = Professors.get_professor_by_id!(id)

    conn
    |> put_view(ProfessorView)
    |> render("show.json", professor: professor)
  end
end
