defmodule SkollerWeb.Api.V1.Admin.Student.ClassController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Class.StudentClassView
  alias Skoller.StudentClasses
  alias Skoller.StudentAssignments
  alias Skoller.EnrolledStudents
  alias Skoller.Mods.Assignments

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  @admin_role 200
  
  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_member, :student
  plug :verify_member, %{of: :class, using: :id}
  plug :verify_class_is_editable, :class_id

  def index(conn, %{"student_id" => student_id}) do
    student_classes = EnrolledStudents.get_enrolled_classes_by_student_id(student_id)
    |> Enum.map(&add_student_class_details(&1))

    render(conn, StudentClassView, "index.json", student_classes: student_classes)
  end

  #TODO: Find way to wrap this into a context in a way that makes sense.
  defp add_student_class_details(student_class) do
    student_class
    |> Map.put(:grade, StudentClasses.get_class_grade(student_class.id))
    |> Map.put(:completion, StudentAssignments.get_class_completion(student_class))
    |> Map.put(:enrollment, EnrolledStudents.get_enrollment_by_class_id(student_class.class.id))
    |> Map.put(:new_assignments, Assignments.get_new_assignment_mods(student_class))
  end
end