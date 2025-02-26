defmodule SkollerWeb.Api.V1.Student.SchoolController do
  @moduledoc false
  use SkollerWeb, :controller

  alias Skoller.StudentClasses
  alias Skoller.EnrolledStudents
  alias SkollerWeb.SchoolView

  import SkollerWeb.Plugs.Auth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def show(conn, %{"student_id" => student_id}) do
    school =
      student_id
      |> EnrolledStudents.get_enrolled_classes_by_student_id()
      |> StudentClasses.get_most_common_school()

    conn
    |> put_view(SchoolView)
    |> render("show.json", school: school)
  end
end
