defmodule SkollerWeb.Api.V1.Student.ClassController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Class.StudentClassView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.Mods
  alias Skoller.StudentClasses
  alias Skoller.StudentAssignments
  alias Skoller.EnrolledStudents
  alias Skoller.StudentClasses.EnrollmentLinks

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student
  plug :verify_class_is_editable, :class_id

  def create(conn, %{"student_id" => student_id, "class_id" => class_id} = params) do
    case StudentClasses.enroll_in_class(student_id, class_id, params) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def link(conn, %{"token" => token} = params) do
    case EnrollmentLinks.enroll_by_link(token, conn.assigns[:user].student.id, params) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end


  def show(conn, %{"student_id" => student_id, "class_id" => class_id}) do
    student_class = EnrolledStudents.get_enrolled_class_by_ids!(class_id, student_id)

    student_class = student_class
      |> Map.put(:grade, StudentClasses.get_class_grade(student_class.id))
      |> Map.put(:completion, StudentAssignments.get_class_completion(student_class))
      |> Map.put(:enrollment, EnrolledStudents.get_enrollment_by_class_id(class_id))
      |> Map.put(:new_assignments, get_new_class_assignments(student_class))

    render(conn, StudentClassView, "show.json", student_class: student_class)
  end

  def update(conn, %{"student_id" => student_id, "class_id" => class_id} = params) do
    old = EnrolledStudents.get_enrolled_class_by_ids!(class_id, student_id)

    case EnrolledStudents.update_enrolled_class(old, params) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"student_id" => student_id, "class_id" => class_id}) do
    student_class = EnrolledStudents.get_enrolled_class_by_ids!(class_id, student_id)

    case EnrolledStudents.drop_enrolled_class(student_class) do
      {:ok, _student_class} ->
        conn |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp get_new_class_assignments(%{} = student_class) do
    student_class |> Mods.get_new_assignment_mods()
  end
end