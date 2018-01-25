defmodule ClassnavapiWeb.Class.StudentRequestView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentRequestView
  alias ClassnavapiWeb.Class.StudentRequest.TypeView

  def render("show.json", %{student_request: student_request}) do
    render_one(student_request, StudentRequestView, "student_request.json")
  end

  def render("student_request.json", %{student_request: student_request}) do
    student_request = student_request |> Repo.preload(:class_student_request_type)
    %{
      notes: student_request.notes,
      is_completed: student_request.is_completed,
      id: student_request.id,
      change_type: render_one(student_request.class_student_request_type, TypeView, "type.json")
    }
  end
end
