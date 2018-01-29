defmodule ClassnavapiWeb.Class.DocView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.DocView
  alias Classnavapi.Repo
  alias ClassnavapiWeb.UserView
  alias ClassnavapiWeb.ClassView

  def render("index.json", %{docs: docs}) do
    render_many(docs, DocView, "doc.json")
  end

  def render("show.json", %{doc: doc}) do
    render_one(doc, DocView, "doc.json")
  end

  def render("doc.json", %{doc: doc}) do
    doc = doc |> Repo.preload([:user, :class])
    %{
      path: doc.path,
      class: render_one(doc.class, ClassView, "class.json"),
      is_syllabus: doc.is_syllabus,
      name: doc.name,
      id: doc.id,
      user: render_one(doc.user, UserView, "user.json")
    }
  end

  def render("doc-short.json", %{doc: doc}) do
    %{
      path: doc.path,
      is_syllabus: doc.is_syllabus,
      name: doc.name,
      id: doc.id,
    }
  end
end
