defmodule SkollerWeb.Admin.StudentClassView do
  use SkollerWeb, :view

  alias Skoller.Repo
  alias SkollerWeb.StudentView

  @enrollment_path "/e/"

  def render("student_class.json", %{student_class: student_class}) do
    student_class = student_class |> Repo.preload([:student_assignments, :student])
    render_one(student_class.student, StudentView, "student-short.json")
    |> Map.merge(
      %{
        color: student_class.color,
        is_class_notifications: student_class.is_notifications,
        enrollment_link: System.get_env("WEB_URL") <> @enrollment_path <> student_class.enrollment_link,
        is_dropped: student_class.is_dropped
      }
    )
  end
end