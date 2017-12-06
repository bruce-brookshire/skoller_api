defmodule ClassnavapiWeb.Class.DocView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.DocView

  def render("index.json", %{docs: docs}) do
    render_many(docs, DocView, "doc.json")
  end

  def render("show.json", %{doc: doc}) do
    render_one(doc, DocView, "doc.json")
  end

  def render("doc.json", %{doc: doc}) do
    %{
      path: doc.path,
      class_id: doc.class_id,
      is_syllabus: doc.is_syllabus,
      name: doc.name
    }
  end
end
