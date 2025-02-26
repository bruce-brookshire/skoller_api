defmodule SkollerWeb.Api.V1.Student.StudentReferralsController do
  @moduledoc false

  use SkollerWeb, :controller

  import Plug.Conn

  alias SkollerWeb.Student.ReferredStudentsView
  alias Skoller.Students

  def referred_students(conn, %{"student_id" => student_id}) do
    student = Students.get_student_by_id!(student_id)
    referred_students = Students.get_referred_students_by_student_id(student_id)

    conn
    |> put_view(ReferredStudentsView)
    |> render("referred_students.json", referred_students: referred_students, student: student)
  end
end
