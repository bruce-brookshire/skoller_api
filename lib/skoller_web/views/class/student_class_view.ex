defmodule SkollerWeb.Class.StudentClassView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Class.StudentClassView
  alias SkollerWeb.ClassView
  alias SkollerWeb.Class.WeightView
  alias Skoller.Repo
  alias SkollerWeb.Class.StudentAssignmentView
  alias SkollerWeb.Assignment.ModView
  alias Skoller.StudentAssignments
  alias SkollerWeb.StudentView

  @enrollment_path "/e/"

  def render("index.json", %{student_classes: student_classes}) do
    render_many(student_classes, StudentClassView, "student_class.json")
  end

  def render("show.json", %{student_class: student_class}) do
    render_one(student_class, StudentClassView, "student_class.json")
  end

  def render("student_class.json", %{student_class: %{grade: grade, completion: completion, enrollment: enrollment, new_assignments: new_assignments, students: students} = student_class}) do
    student_class
    |> base_student_class()
    |> Map.merge(%{
      grade: Decimal.to_float(Decimal.round(grade, 2)),
      completion: Decimal.to_float(Decimal.round(completion, 2)),
      enrollment: enrollment,
      new_assignments: render_many(new_assignments, ModView, "mod.json"),
      students: render_many(students, StudentView, "student-short.json")
    })
  end

  def render("student_class.json", %{student_class: %{grade: grade, completion: completion, enrollment: enrollment, new_assignments: new_assignments} = student_class}) do
    student_class
    |> base_student_class()
    |> Map.merge(%{
      grade: Decimal.to_float(Decimal.round(grade, 2)),
      completion: Decimal.to_float(Decimal.round(completion, 2)),
      enrollment: enrollment,
      new_assignments: render_many(new_assignments, ModView, "mod.json")
    })
  end

  def render("student_class.json", %{student_class: student_class}) do
    base_student_class(student_class)
  end

  defp base_student_class(student_class) do
    student_class = student_class |> Repo.preload([:class, :student_assignments])
    class = student_class.class |> Repo.preload(:weights)
    %{
      student_id: student_class.student_id,
      color: student_class.color,
      is_notifications: student_class.is_notifications,
      assignments: render_many(get_ordered_assignments(student_class), StudentAssignmentView, "student_assignment.json"),
      weights: render_many(class.weights, WeightView, "weight.json"),
      enrollment_link: System.get_env("WEB_URL") <> @enrollment_path <> student_class.enrollment_link
    } 
    |> Map.merge(render_one(student_class.class, ClassView, "class.json"))
  end

  defp get_ordered_assignments(student_class) do
    StudentAssignments.get_assignments_with_relative_weight(student_class)
    |> order()
  end

  defp order(enumerable) do
    null_due = enumerable
    |> Enum.filter(&is_nil(&1.due))

    sorted = enumerable
    |> Enum.filter(&not(is_nil(&1.due)))
    |> Enum.sort(&DateTime.compare(&1.due, &2.due) in [:lt, :eq])

    null_due ++ sorted
  end
end
  