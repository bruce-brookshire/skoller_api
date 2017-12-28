defmodule ClassnavapiWeb.Class.StudentClassView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.StudentClassView
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.Class.WeightView
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.AssignmentView
  alias ClassnavapiWeb.Helpers.ClassCalcs
  alias ClassnavapiWeb.Class.StatusView

  def render("index.json", %{student_classes: student_classes}) do
    render_many(student_classes, StudentClassView, "student_class.json")
  end

  def render("show.json", %{student_class: student_class}) do
    render_one(student_class, StudentClassView, "student_class.json")
  end

  def render("student_class.json", %{student_class: %{grade: grade, completion: completion, enrollment: enrollment, status: status, new_assignments: new_assignments} = student_class}) do
    student_class
    |> base_student_class()
    |> Map.merge(%{
      grade: Decimal.to_float(grade),
      completion: Decimal.to_float(completion),
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
      assignments: render_many(ClassCalcs.get_assignments_with_relative_weight(student_class), StudentAssignmentView, "student_assignment.json"),
      weights: render_many(class.weights, WeightView, "weight.json"),
    } 
    |> Map.merge(render_one(student_class.class, ClassView, "class.json"))
  end
end
  