defmodule ClassnavapiWeb.StudentView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.StudentView

  def render("index.json", %{students: students}) do
    render_many(students, StudentView, "student.json")
  end

  def render("show.json", %{student: student}) do
    render_one(student, StudentView, "student.json")
  end

  def render("student.json", %{student: student}) do
    %{name_first: student.name_first,
      name_last: student.name_last,
      phone: student.phone,
      major: student.major,
      birthday: student.birthday,
      gender: student.gender}
  end
end
