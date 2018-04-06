defmodule ClassnavapiWeb.Api.V1.Student.Class.GradeController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Universities.Class

  import ClassnavapiWeb.Helpers.AuthPlug
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
            |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
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