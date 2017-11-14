defmodule ClassnavapiWeb.Class.StudentAssignmentView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.StudentAssignmentView

  def render("index.json", %{student_assignments: student_assignments}) do
    render_many(student_assignments, StudentAssignmentView, "student_assignment.json")
  end

  def render("show.json", %{student_assignment: student_assignment}) do
    render_one(student_assignment, StudentAssignmentView, "student_assignment.json")
  end

  def render("student_assignment.json", %{student_assignment: student_assignment}) do
    %{
      id: student_assignment.id,
      student_class_id: student_assignment.student_class_id,
      assignment_id: student_assignment.assignment_id,
      grade: student_assignment.grade
    }
  end
end
  