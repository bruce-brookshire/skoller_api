defmodule ClassnavapiWeb.CSVView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.CSVView
  alias ClassnavapiWeb.ChangesetView
  alias Classnavapi.School.FieldOfStudy
  alias ClassnavapiWeb.School.FieldOfStudyView
  alias Classnavapi.Class
  alias ClassnavapiWeb.ClassView

  def render("index.json", %{csv: csv}) do
    render_many(csv, CSVView, "csv.json")
  end

  def render("csv.json", %{csv: {:ok, %Class{} = class}}) do
    render_one(class, ClassView, "class.json")
  end

  def render("csv.json", %{csv: {:ok, %FieldOfStudy{} = fos}}) do
    render_one(fos, FieldOfStudyView, "field.json", as: :field)
  end

  def render("csv.json", %{csv: {:error, %Ecto.Changeset{} = changeset}}) do
    changeset.changes |> Map.merge(
      render_one(changeset, ChangesetView, "error.json")
    )
  end

  def render("csv.json", %{csv: {:error, text}}) do
    %{
      error: text
    }
  end
end
