defmodule ClassnavapiWeb.Class.DocView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.DocView
  alias Classnavapi.Repo
  alias ClassnavapiWeb.UserView

  def render("index.json", %{docs: docs}) do
    render_many(docs, DocView, "doc.json")
  end

  def render("show.json", %{doc: doc}) do
    render_one(doc, DocView, "doc.json")
  end

  def render("doc.json", %{doc: doc}) do
    doc = doc |> Repo.preload(:user)
    %{
      path: doc.path,
      class_id: doc.class_id,
      is_syllabus: doc.is_syllabus,
      name: doc.name,
      id: doc.id,
      user: render_one(doc.user, UserView, "user.json")
    }
  end
end
