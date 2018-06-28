defmodule SkollerWeb.Api.V1.Student.Class.LinkController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Students
  alias SkollerWeb.Student.Class.LinkView

  def show(conn, %{"token" => token}) do
    student_class = Students.get_student_class_by_enrollment_link(token)
    render(conn, LinkView, "show.json", link: student_class)
  end
end