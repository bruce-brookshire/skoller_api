defmodule SkollerWeb.Api.V1.Organization.OrgGroupStudent.ClassesController do
  use SkollerWeb, :controller

  alias SkollerWeb.Class.StudentClassView
  alias Skoller.StudentClasses
  alias Skoller.StudentAssignments
  alias Skoller.EnrolledStudents
  alias Skoller.Mods.Assignments
  alias Skoller.Organizations.OrgGroupStudents

  def index(conn, %{"org_group_student_id" => org_student_id} = params) do
    %{student: %{id: student_id}} = OrgGroupStudents.get_by_id(org_student_id) |> IO.inspect

    student_classes =
      EnrolledStudents.get_enrolled_classes_by_student_id(student_id)
      |> Enum.map(&add_student_class_details(&1))

    conn
    |> put_view(StudentClassView)
    |> render("index.json", student_classes: student_classes)
  end

  defp add_student_class_details(student_class) do
    student_class
    |> Map.put(:grade, StudentClasses.get_class_grade(student_class.id))
    |> Map.put(:completion, StudentAssignments.get_class_completion(student_class))
    |> Map.put(:enrollment, EnrolledStudents.get_enrollment_by_class_id(student_class.class.id))
    |> Map.put(:new_assignments, Assignments.get_new_assignment_mods(student_class))
  end
end
