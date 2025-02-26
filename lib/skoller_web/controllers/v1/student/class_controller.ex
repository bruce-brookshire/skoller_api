defmodule SkollerWeb.Api.V1.Student.ClassController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Class.StudentClassView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.StudentClasses
  alias Skoller.StudentAssignments
  alias Skoller.EnrolledStudents
  alias Skoller.StudentClasses.EnrollmentLinks
  alias Skoller.Mods.Assignments
  alias Skoller.ClassDocs

  import SkollerWeb.Plugs.Auth, only: [verify_role: 2, verify_member: 2, verify_class_is_editable: 2]
  import SkollerWeb.Plugs.InsightsAuth, only: [verify_access: 2]

  @student_role 100
  @insights_role 700

  plug :verify_role, %{roles: [@student_role, @insights_role]}
  plug :verify_member, :student
  plug :verify_class_is_editable, :class_id
  plug :verify_access, :student_id when action in [:create, :delete]

  def create(conn, %{"student_id" => student_id, "class_id" => class_id} = params) do
    case StudentClasses.enroll_in_class(student_id, class_id, params) do
      {:ok, student_class} ->
        conn
        |> put_view(StudentClassView)
        |> render("show.json", student_class: student_class)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def link(conn, %{"token" => token} = params) do
    case EnrollmentLinks.enroll_by_link(token, conn.assigns[:user].student.id, params) do
      {:ok, student_class} ->
        conn
        |> put_view(StudentClassView)
        |> render("show.json", student_class: student_class)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def show(conn, %{"student_id" => student_id, "class_id" => class_id}) do
    student_class = EnrolledStudents.get_enrolled_class_by_ids!(class_id, student_id)

    student_class =
      student_class
      |> Map.put(:grade, StudentClasses.get_class_grade(student_class.id))
      |> Map.put(:completion, StudentAssignments.get_class_completion(student_class))
      |> Map.put(:enrollment, EnrolledStudents.get_enrollment_by_class_id(class_id))
      |> Map.put(:new_assignments, get_new_class_assignments(student_class))
      |> Map.put(:students, EnrolledStudents.get_students_by_class(class_id))
      |> Map.put(
        :documents,
        ClassDocs.get_docs_by_class(student_class.class_id)
        |> Enum.map(fn elem -> %{name: elem.name, path: elem.path} end)
      )

    conn
    |> put_view(StudentClassView)
    |> render("show.json", student_class: student_class)
  end

  def update(conn, %{"student_id" => student_id, "class_id" => class_id} = params) do
    old = EnrolledStudents.get_enrolled_class_by_ids!(class_id, student_id)

    case EnrolledStudents.update_enrolled_class(old, params) do
      {:ok, student_class} ->
        conn
        |> put_view(StudentClassView)
        |> render("show.json", student_class: student_class)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
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
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  defp get_new_class_assignments(%{} = student_class) do
    student_class |> Assignments.get_new_assignment_mods()
  end
end
