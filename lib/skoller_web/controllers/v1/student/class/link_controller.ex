defmodule SkollerWeb.Api.V1.Student.Class.LinkController do
  use SkollerWeb, :controller

  alias SkollerWeb.Class.StudentClassView
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Students
  alias SkollerWeb.Student.Class.LinkView

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student
  plug :verify_class_is_editable, :class_id

  def create(conn, %{"token" => token} = params) do
    case Students.enroll_by_link(token, conn.assigns[:user].student.id, params) do
      {:ok, student_class} ->
        render(conn, StudentClassView, "show.json", student_class: student_class)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def show(conn, %{"token" => token}) do
    student_class = Students.get_student_class_by_enrollment_link(token)
    render(conn, LinkView, "show.json", link: student_class)
  end
end