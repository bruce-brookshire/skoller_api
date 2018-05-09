defmodule ClassnavapiWeb.Class.StudentClassView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.StudentClassView
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.Class.WeightView
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.AssignmentView
  alias ClassnavapiWeb.Helpers.ClassCalcs

  def render("index.json", %{student_classes: student_classes}) do
    render_many(student_classes, StudentClassView, "student_class.json")
  end

  def render("show.json", %{student_class: student_class}) do
    render_one(student_class, StudentClassView, "student_class.json")
  end

  def render("student_class.json", %{student_class: %{grade: grade, completion: completion, enrollment: enrollment, new_assignments: new_assignments} = student_class}) do
    student_class
    |> base_student_class()
    |> Map.merge(%{
      grade: Decimal.to_float(Decimal.round(grade, 2)),
      completion: Decimal.to_float(Decimal.round(completion, 2)),
      enrollment: enrollment,
      new_assignments: render_many(new_assignments, AssignmentView, "assignment.json")
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
    } 
    |> Map.merge(render_one(student_class.class, ClassView, "class.json"))
  end

  defp get_ordered_assignments(student_class) do
    ClassCalcs.get_assignments_with_relative_weight(student_class)
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
  