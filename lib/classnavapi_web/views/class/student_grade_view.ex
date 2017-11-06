defmodule ClassnavapiWeb.Class.StudentGradeView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.StudentGradeView

  def render("index.json", %{student_grades: student_grades}) do
    render_many(student_grades, StudentGradeView, "student_grade.json")
  end

  def render("show.json", %{student_grade: student_grade}) do
    render_one(student_grade, StudentGradeView, "student_grade.json")
  end

  def render("student_grade.json", %{} = params) do
    require IEx
    IEx.pry
    %{
      student_class_id: params.student_class_id,
      assignment_id: params.assignment_id,
      grade: params.grade
    }
  end
end
  