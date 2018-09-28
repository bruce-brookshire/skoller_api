defmodule SkollerWeb.Api.V1.Student.Class.LinkController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.StudentClasses.EnrollmentLinks
  alias SkollerWeb.Student.Class.LinkView

  def show(conn, %{"token" => token}) do
    student_class = EnrollmentLinks.get_student_class_by_enrollment_link(token)
    render(conn, LinkView, "show.json", link: student_class)
  end
end