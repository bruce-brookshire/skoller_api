defmodule SkollerWeb.Api.V1.Student.SchoolController do
  @moduledoc false
  use SkollerWeb, :controller

  alias Skoller.StudentClasses
  alias Skoller.Students
  alias SkollerWeb.SchoolView

  def show(conn, %{"student_id" => student_id}) do
    school = student_id
    |> Students.get_enrolled_classes_by_student_id()
    |> StudentClasses.get_most_common_school()

    render(conn, SchoolView, "show.json", school: school)
  end
end