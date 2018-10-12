defmodule SkollerWeb.Class.StudentAssignmentView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Class.StudentAssignmentView
  alias SkollerWeb.AssignmentView
  alias SkollerWeb.Assignment.ModView
  alias Skoller.Repo

  def render("index.json", %{student_assignments: student_assignments}) do
    render_many(student_assignments, StudentAssignmentView, "student_assignment.json")
  end

  def render("show.json", %{student_assignment: student_assignment}) do
    render_one(student_assignment, StudentAssignmentView, "student_assignment.json")
  end

  def render("student_assignment.json", %{student_assignment: student_assignment}) do
    student_assignment = student_assignment |> Repo.preload([:assignment, :student_class])

    student_assignment
    |> render_one(AssignmentView, "assignment.json")
    |> Map.merge(%{
      id: student_assignment.id,
      student_id: student_assignment.student_class.student_id,
      class_id: student_assignment.student_class.class_id,
      grade: get_grade(student_assignment),
      assignment_id: student_assignment.assignment_id,
      is_completed: is_completed(student_assignment.is_completed),
      is_reminder_notifications: student_assignment.is_reminder_notifications,
      is_post_notifications: student_assignment.is_post_notifications,
      notes: student_assignment.notes,
      is_read: student_assignment.is_read
    })
    |> Map.merge(get_pending_mods(student_assignment))
  end

  def render("student_assignment-short.json", %{student_assignment: student_assignment}) do
    student_assignment = student_assignment |> Repo.preload([:assignment, :student_class])

    student_assignment
    |> render_one(AssignmentView, "assignment-short.json")
    |> Map.merge(%{
      id: student_assignment.id,
      student_id: student_assignment.student_class.student_id,
      class_id: student_assignment.student_class.class_id,
      grade: get_grade(student_assignment),
      assignment_id: student_assignment.assignment_id,
      is_completed: is_completed(student_assignment.is_completed),
      is_reminder_notifications: student_assignment.is_reminder_notifications,
      is_post_notifications: student_assignment.is_post_notifications,
      notes: student_assignment.notes,
      is_read: student_assignment.is_read
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

  defp get_grade(%{grade: nil}), do: nil
  defp get_grade(%{grade: grade}), do: Decimal.to_float(Decimal.round(grade, 2))

  defp is_completed(nil), do: false
  defp is_completed(val), do: val
end
  