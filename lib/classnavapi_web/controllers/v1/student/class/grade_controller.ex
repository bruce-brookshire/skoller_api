defmodule ClassnavapiWeb.Api.V1.Student.Class.GradeController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, %{of: :student_assignment, using: :assignment_id}

  def create(conn, %{"assignment_id" => assignment_id} = params) do
    assign_old = Repo.get!(StudentAssignment, assignment_id)

    changeset = StudentAssignment.grade_changeset(assign_old, params)

    case Repo.update(changeset) do
      {:ok, student_assignment} ->
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end