defmodule ClassnavapiWeb.Api.V1.School.FieldController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.School.FieldOfStudy
  alias Classnavapi.School.StudentField
  alias Classnavapi.Repo
  alias ClassnavapiWeb.School.FieldOfStudyView

  import Ecto.Query

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
    query = (from fs in FieldOfStudy)
    fields = query
            |> join(:left, [fs], st in StudentField, fs.id == st.field_of_study_id)
            |> where([fs], fs.school_id == ^school_id)
            |> group_by([fs, st], [fs.field, fs.id])
            |> select([fs, st], %{field: fs, count: count(st.id)})
            |> Repo.all()
    render(conn, FieldOfStudyView, "index.json", fields: fields)
  end

  def show(conn, %{"id" => id}) do
    field = Repo.get!(FieldOfStudy, id)
    render(conn, FieldOfStudyView, "show.json", field: field)
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