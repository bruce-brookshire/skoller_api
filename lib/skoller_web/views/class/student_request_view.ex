defmodule SkollerWeb.Class.StudentRequestView do
  @moduledoc false
  use SkollerWeb, :view

  alias Skoller.Repo
  alias SkollerWeb.Class.StudentRequestView
  alias SkollerWeb.Class.StudentRequest.TypeView
  alias SkollerWeb.Class.DocView
  alias SkollerWeb.UserView

  import Ecto.Query

  def render("show.json", %{student_request: student_request}) do
    render_one(student_request, StudentRequestView, "student_request.json")
  end

  def render("student_request.json", %{student_request: student_request}) do
    student_request = student_request |> Repo.preload([:class_student_request_type, :user])
    docs = from(d in Skoller.Class.Doc)
    |> join(:inner, [d], srd in Skoller.StudentRequests.Doc, srd.doc_id == d.id)
    |> where([d, srd], srd.class_student_request_id == ^student_request.id)
    |> Repo.all()
    %{
      docs: render_many(docs, DocView, "doc-short.json"),
      notes: student_request.notes,
      is_completed: student_request.is_completed,
      id: student_request.id,
      user: render_one(student_request.user, UserView, "user.json"),
      change_type: render_one(student_request.class_student_request_type, TypeView, "type.json")
    }
  end
end
