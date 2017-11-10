defmodule ClassnavapiWeb.Class.StudentClassView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.StudentClassView
  alias ClassnavapiWeb.ClassView
  alias Classnavapi.Repo

  def render("index.json", %{student_classes: student_classes}) do
    render_many(student_classes, StudentClassView, "student_class.json")
  end

  def render("show.json", %{student_class: student_class}) do
    render_one(student_class, StudentClassView, "student_class.json")
  end

  def render("student_class.json", %{student_class: %{grade: grade} = student_class}) do
    student_class
    |> base_student_class()
    |> Map.merge(%{
      grade: grade
    })
  end

  def render("student_class.json", %{student_class: student_class, grade: grade}) do
    student_class
    |> base_student_class()
    |> Map.merge(%{
      grade: grade
    })
  end

  def render("student_class.json", %{student_class: student_class}) do
    base_student_class(student_class)
  end

  defp base_student_class(student_class) do
    student_class = student_class |> Repo.preload(:class)
    %{
      student_id: student_class.student_id
    } 
    |> Map.merge(
        %{
          class: render_one(student_class.class, ClassView, "class.json")
        })
  end
end
  