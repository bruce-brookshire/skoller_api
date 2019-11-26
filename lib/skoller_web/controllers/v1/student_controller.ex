defmodule SkollerWeb.Api.V1.StudentController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Students
  alias SkollerWeb.StudentView

  def show(conn, %{"token" => token}) do
    student = Students.get_student_by_enrollment_link!(token)

    conn
    |> put_view(StudentView)
    |> render("show.json", link: student)
  end
end
