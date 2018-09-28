defmodule SkollerWeb.Api.V1.Admin.Student.ClassController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Class.StudentClassView
  alias Skoller.Mods
  alias Skoller.Students
  alias Skoller.StudentClasses
  alias Skoller.StudentAssignments
  alias Skoller.EnrolledStudents

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  @admin_role 200
  
  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_member, :student
  plug :verify_member, %{of: :class, using: :id}
  plug :verify_class_is_editable, :class_id

  def index(conn, %{"student_id" => student_id}) do
    student_classes = EnrolledStudents.get_enrolled_classes_by_student_id(student_id)
    |> Enum.map(&Map.put(&1, :grade, StudentClasses.get_class_grade(&1.id)))
    |> Enum.map(&Map.put(&1, :completion, StudentAssignments.get_class_completion(&1)))
    |> Enum.map(&Map.put(&1, :enrollment, Students.get_enrollment_by_class_id(&1.class.id)))
    |> Enum.map(&Map.put(&1, :new_assignments, get_new_class_assignments(&1)))

    render(conn, StudentClassView, "index.json", student_classes: student_classes)
  end

  defp get_new_class_assignments(%{} = student_class) do
    student_class |> Mods.get_new_assignment_mods()
  end
end