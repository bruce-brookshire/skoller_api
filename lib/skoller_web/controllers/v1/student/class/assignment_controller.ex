defmodule SkollerWeb.Api.V1.Student.Class.AssignmentController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Class.StudentAssignmentView
  alias Skoller.StudentAssignments
  alias Skoller.EnrolledStudents
  alias Skoller.StudentAssignments.StudentClasses
  alias Skoller.Mods.StudentAssignments, as: StudentAssignmentMods

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :class
  plug :verify_member, :student
  plug :verify_member, %{of: :student_assignment, using: :id}
  plug :verify_class_is_editable, :class_id

  def create(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do
    student_class = EnrolledStudents.get_enrolled_class_by_ids!(class_id, student_id)

    params = params |> Map.put("student_class_id", student_class.id)

    case StudentAssignments.create_student_assignment(params) do
      {:ok, student_assignment} ->
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"student_id" => student_id} = params) do
    student_assignments = StudentClasses.get_student_assignments(student_id, params)
    render(conn, StudentAssignmentView, "index.json", student_assignments: student_assignments)
  end

  def show(conn, %{"id" => id}) do
    student_assignment = StudentClasses.get_student_assignment_by_id(id, :weight)
    
    pending_mods = StudentAssignmentMods.pending_mods_for_student_assignment(student_assignment)
    student_assignment = student_assignment |> Map.put(:pending_mods, pending_mods)

    render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
  end

  def update(conn, %{"id" => id} = params) do
    student_assignment = StudentClasses.get_student_assignment_by_id!(id)

    case StudentAssignments.update_student_assignment(student_assignment, params) do
      {:ok, student_assignment} ->
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id} = params) do
    student_assignment = StudentClasses.get_student_assignment_by_id!(id)

    case StudentAssignments.delete_student_assignment(student_assignment, params["is_private"]) do
      {:ok, _results} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end