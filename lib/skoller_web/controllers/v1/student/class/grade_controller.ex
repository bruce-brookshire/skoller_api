defmodule SkollerWeb.Api.V1.Student.Class.GradeController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.StudentAssignments
  alias SkollerWeb.Class.StudentAssignmentView
  alias Skoller.StudentAssignments.StudentClasses

  import SkollerWeb.Plugs.Auth, only: [verify_role: 2, verify_member: 2]
  import SkollerWeb.Plugs.InsightsAuth, only: [verify_access: 2]

  @student_role 100
  @insights_role 700

  plug :verify_role, %{roles: [@student_role, @insights_role]}
  plug :verify_member, %{of: :student_assignment, using: :assignment_id}
  plug :verify_access, :assignment_id

  def create(conn, %{"assignment_id" => assignment_id} = params) do
    assign_old = StudentClasses.get_student_assignment_by_id!(assignment_id)

    case StudentAssignments.update_assignment_grade(assign_old, params) do
      {:ok, student_assignment} ->
        conn
        |> put_view(StudentAssignmentView)
        |> render("show.json", student_assignment: student_assignment)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
