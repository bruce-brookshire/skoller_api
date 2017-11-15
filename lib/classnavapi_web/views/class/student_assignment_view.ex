defmodule ClassnavapiWeb.Class.StudentAssignmentView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.AssignmentView
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
      grade: student_assignment.grade
    })
  end
end
  