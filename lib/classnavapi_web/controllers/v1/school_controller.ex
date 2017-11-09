defmodule ClassnavapiWeb.Api.V1.SchoolController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.School
  alias Classnavapi.Student
  alias Classnavapi.Repo
  alias ClassnavapiWeb.SchoolView

  import Ecto.Query

  def create(conn, %{} = params) do

    changeset = School.changeset_insert(%School{}, params)

    case Repo.insert(changeset) do
      {:ok, school} ->
        render(conn, SchoolView, "show.json", school: school)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, _) do
    student_subquery = from(student in Student)
    student_subquery = student_subquery
              |> group_by([student], student.school_id)
              |> select([student], %{school_id: student.school_id, count: count(student.id)})

    query = from(school in School)
    schools = query
              |> join(:left, [school], student in subquery(student_subquery), student.school_id == school.id)
              |> select([school, student], %{school: school, students: student.count})
              |> Repo.all()
    
    render(conn, SchoolView, "index.json", schools: schools)
  end

  def show(conn, %{"id" => id}) do
    school = Repo.get!(School, id)
    render(conn, SchoolView, "show.json", school: school)
  end

  def update(conn, %{"id" => id} = params) do
    school_old = Repo.get!(School, id)
    school_old = school_old |> Repo.preload(:email_domains)
    
    changeset = School.changeset_update(school_old, params)

    case Repo.update(changeset) do
      {:ok, school} ->
        render(conn, SchoolView, "show.json", school: school)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end