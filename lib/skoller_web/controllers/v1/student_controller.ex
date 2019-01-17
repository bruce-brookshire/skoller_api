defmodule SkollerWeb.Api.V1.StudentController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Students.Student
  alias SkollerWeb.StudentView

  def show(conn, %{"token" => token}) do
    student = Student.get_student_by_student_link(token)
    render(conn, StudentView, "show.json", link: student)
  end
end