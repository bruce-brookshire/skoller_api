defmodule SkollerWeb.Api.V1.Admin.ProfessorController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Professors
  alias SkollerWeb.ProfessorView

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200
  @change_req_role 400
  @insights_role 700 

  plug :verify_role, %{roles: [@student_role, @admin_role, @change_req_role, @insights_role]}

  def update(%{assigns: %{user: user}} = conn, %{"id" => id} = params) do
    professor_old = Professors.get_professor_by_id!(id)

    case Professors.update_professor(professor_old, params, user) do
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
end
