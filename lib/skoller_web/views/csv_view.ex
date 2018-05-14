defmodule SkollerWeb.CSVView do
  use SkollerWeb, :view

  alias SkollerWeb.CSVView
  alias SkollerWeb.ChangesetView
  alias Skoller.FieldsOfStudy.FieldOfStudy
  alias SkollerWeb.School.FieldOfStudyView
  alias Skoller.Schools.Class
  alias SkollerWeb.ClassView

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
