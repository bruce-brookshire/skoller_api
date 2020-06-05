defmodule SkollerWeb.CSVView do
  @moduledoc false
  use SkollerWeb, :view

  alias Skoller.Organizations.StudentOrgInvitations.StudentOrgInvitation
  alias SkollerWeb.School.FieldOfStudyView
  alias Skoller.FieldsOfStudy.FieldOfStudy
  alias SkollerWeb.Organization.StudentOrgInvitationView
  alias SkollerWeb.ChangesetView
  alias Skoller.Schools.School
  alias SkollerWeb.SchoolView
  alias Skoller.Classes.Class
  alias SkollerWeb.ClassView
  alias SkollerWeb.CSVView
  
  def render("index.json", %{csv: csv}) do
    render_many(csv, CSVView, "csv.json")
  end

  def render("csv.json", %{csv: {:ok, %{class: %Class{} = class}}}) do
    render_one(class, ClassView, "class.json")
  end

  def render("csv.json", %{csv: {:ok, %FieldOfStudy{} = fos}}) do
    render_one(fos, FieldOfStudyView, "field.json", as: :field)
  end

  def render("csv.json", %{csv: {:ok, %School{} = school}}) do
    render_one(school, SchoolView, "show.json")
  end
  
  def render("csv.json", %{csv: {:error, %Ecto.Changeset{} = changeset}}) do
    changeset.changes |> Map.merge(
      render_one(changeset, ChangesetView, "error.json")
    )
  end

  def render("csv.json", %{csv: {:error, :class, %Ecto.Changeset{} = changeset, _}}) do
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
