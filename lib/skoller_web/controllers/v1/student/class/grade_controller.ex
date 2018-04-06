defmodule SkollerWeb.Api.V1.Student.Class.GradeController do
  use SkollerWeb, :controller

  alias Skoller.Class.StudentAssignment
  alias Skoller.Repo
  alias SkollerWeb.Class.StudentAssignmentView
  alias Skoller.Class.StudentClass
  alias Skoller.Schools.Class

  import SkollerWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, %{of: :student_assignment, using: :assignment_id}

  def create(conn, %{"assignment_id" => assignment_id} = params) do
    case get_student_assignment(assignment_id) do
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
      assign_old -> 
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

  defp get_student_assignment(id) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, sc.id == sa.student_class_id)
    |> join(:inner, [sa, sc], class in Class, sc.class_id == class.id)
    |> where([sa], sa.id == ^id)
    |> where([sa, sc, class], class.is_editable == true)
    |> Repo.one()
  end
end