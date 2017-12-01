defmodule ClassnavapiWeb.StudentView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.StudentView
  alias Classnavapi.Repo
  alias ClassnavapiWeb.School.FieldOfStudyView

  def render("index.json", %{students: students}) do
    render_many(students, StudentView, "student.json")
  end

  def render("show.json", %{student: student}) do
    render_one(student, StudentView, "student.json")
  end

  def render("student.json", %{student: student}) do
    student = student |> Repo.preload(:fields_of_study)
    %{
      id: student.id,
      name_first: student.name_first,
      name_last: student.name_last,
      phone: student.phone,
      birthday: student.birthday,
      gender: student.gender,
      is_verified: student.is_verified,
      school_id: student.school_id,
      fields_of_study: render_many(student.fields_of_study, FieldOfStudyView, "field.json", as: :field)
    }
  end
end
