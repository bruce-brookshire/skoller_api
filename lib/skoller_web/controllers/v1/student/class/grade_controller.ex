defmodule SkollerWeb.Api.V1.Student.Class.GradeController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Repo
  alias SkollerWeb.Class.StudentAssignmentView
  alias Skoller.StudentAssignments.StudentClasses

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, %{of: :student_assignment, using: :assignment_id}

  def create(conn, %{"assignment_id" => assignment_id} = params) do
    assign_old = StudentClasses.get_student_assignment_by_id!(assignment_id)

    changeset = StudentAssignment.grade_changeset(assign_old, params)

    case Repo.update(changeset) do
      {:ok, student_assignment} ->
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end