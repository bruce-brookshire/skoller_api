defmodule ClassnavapiWeb.Class.StudentAssignmentView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.AssignmentView
  alias ClassnavapiWeb.Assignment.ModView
  alias Classnavapi.Repo

  def render("index.json", %{student_assignments: student_assignments}) do
    render_many(student_assignments, StudentAssignmentView, "student_assignment.json")
  end

  def render("show.json", %{student_assignment: student_assignment}) do
    render_one(student_assignment, StudentAssignmentView, "student_assignment.json")
  end

  def render("student_assignment.json", %{student_assignment: student_assignment}) do
    student_assignment
    |> Repo.preload(:assignment)
    |> render_one(AssignmentView, "assignment.json")
    |> Map.merge(%{
      id: student_assignment.id,
      student_class_id: student_assignment.student_class_id,
      grade: Decimal.to_float(student_assignment.grade),
      assignment_id: student_assignment.assignment_id,
    })
    |> Map.merge(get_pending_mods(student_assignment))
  end

  defp get_pending_mods(%{pending_mods: pending_mods}) do
    %{pending_mods: render_many(pending_mods, ModView, "mod.json")}
  end
  defp get_pending_mods(%{is_pending_mods: is_pending_mods}) do
    %{is_pending_mods: is_pending_mods}
  end
  defp get_pending_mods(%{}), do: %{}
end
  