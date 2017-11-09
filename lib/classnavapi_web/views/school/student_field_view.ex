defmodule ClassnavapiWeb.School.StudentFieldView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.School.StudentFieldView

  def render("index.json", %{student_fields: student_fields}) do
    render_many(student_fields, StudentFieldView, "student_field.json")
  end

  def render("show.json", %{student_field: student_field}) do
    render_one(student_field, StudentFieldView, "student_field.json")
  end

  def render("student_field.json", %{student_field: student_field}) do
    %{
      field: student_field.field_of_study_id,
      student: student_field.student_id
    }
  end
end
