defmodule ClassnavapiWeb.Class.StudentRequestView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentRequestView
  alias ClassnavapiWeb.Class.StudentRequest.TypeView

  def render("show.json", %{student_request: student_request}) do
    render_one(student_request, StudentRequestView, "change_request.json")
  end

  def render("student_request.json", %{student_request: student_request}) do
    student_request = student_request |> Repo.preload(:class_request_type)
    %{
      note: student_request.note,
      is_completed: student_request.is_completed,
      id: student_request.id,
      change_type: render_one(student_request.class_request_type, TypeView, "type.json")
    }
  end
end
