defmodule ClassnavapiWeb.Class.StudentClassView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.StudentClassView

  def render("index.json", %{student_classes: student_classes}) do
    render_many(student_classes, StudentClassView, "student_class.json")
  end

  def render("show.json", %{student_class: student_class}) do
    render_one(student_class, StudentClassView, "student_class.json")
  end

  def render("student_class.json", %{} = params) do
    require IEx
    IEx.pry
    %{
      student_id: params.student_id,
      class_id: params.class_id
    }
  end
end
  