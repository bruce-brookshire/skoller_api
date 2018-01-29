defmodule ClassnavapiWeb.Class.StudentRequestView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentRequestView
  alias ClassnavapiWeb.Class.StudentRequest.TypeView
  alias ClassnavapiWeb.Class.DocView

  import Ecto.Query

  def render("show.json", %{student_request: student_request}) do
    render_one(student_request, StudentRequestView, "student_request.json")
  end

  def render("student_request.json", %{student_request: student_request}) do
    student_request = student_request |> Repo.preload([:class_student_request_type])
    docs = from(d in Classnavapi.Class.Doc)
    |> join(:inner, [d], srd in Classnavapi.Class.StudentRequest.Doc, srd.doc_id == d.id)
    |> where([d, srd], srd.class_student_request_id == ^student_request.id)
    |> Repo.all()
    %{
      docs: render_many(docs, DocView, "doc-short.json"),
      notes: student_request.notes,
      is_completed: student_request.is_completed,
      id: student_request.id,
      change_type: render_one(student_request.class_student_request_type, TypeView, "type.json")
    }
  end
end
