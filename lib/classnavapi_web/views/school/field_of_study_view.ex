defmodule ClassnavapiWeb.School.FieldOfStudyView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.School.FieldOfStudyView

  def render("index.json", %{fields: fields}) do
    render_many(fields, FieldOfStudyView, "field.json", as: :field)
  end

  def render("show.json", %{field: field}) do
    render_one(field, FieldOfStudyView, "field.json", as: :field)
  end

  def render("field.json", %{field: %{field: field, count: count}}) do
    %{
      id: field.id,
      field: field.field,
      count: count
    }
  end

  def render("field.json", %{field: field}) do
    %{
      id: field.id,
      field: field.field
    }
  end
end
