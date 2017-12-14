defmodule ClassnavapiWeb.CSVView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.CSVView
  alias ClassnavapiWeb.ChangesetView
  alias Classnavapi.School.FieldOfStudy
  alias ClassnavapiWeb.School.FieldOfStudyView

  def render("index.json", %{csv: csv}) do
    render_many(csv, CSVView, "csv.json")
  end

  def render("csv.json", %{csv: {:ok, %FieldOfStudy{} = fos}}) do
    render_one(fos, FieldOfStudyView, "field.json", as: :field)
  end

  def render("csv.json", %{csv: {:error, %Ecto.Changeset{} = changeset}}) do
    changeset.changes |> Map.merge(
      render_one(changeset, ChangesetView, "error.json")
    )
  end
end
