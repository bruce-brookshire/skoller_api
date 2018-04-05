defmodule ClassnavapiWeb.Api.V1.Admin.School.FieldController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias ClassnavapiWeb.School.FieldOfStudyView
  alias Classnavapi.Students
  alias Classnavapi.School.FieldOfStudy

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(conn, %{} = params) do

    changeset = FieldOfStudy.changeset(%FieldOfStudy{}, params)

    case Repo.insert(changeset) do
      {:ok, field} ->
        render(conn, FieldOfStudyView, "show.json", field: field)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"school_id" => school_id}) do
    fields = Students.get_field_of_study_count_by_school_id(school_id)
    render(conn, FieldOfStudyView, "index.json", fields: fields)
  end

  def update(conn, %{"id" => id} = params) do
    field_old = Repo.get!(FieldOfStudy, id)
    changeset = FieldOfStudy.changeset(field_old, params)

    case Repo.update(changeset) do
      {:ok, field} ->
        render(conn, FieldOfStudyView, "show.json", field: field)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end