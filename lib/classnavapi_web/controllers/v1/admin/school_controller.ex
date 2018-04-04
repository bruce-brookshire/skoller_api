defmodule ClassnavapiWeb.Api.V1.Admin.SchoolController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.School
  alias Classnavapi.Class
  alias Classnavapi.ClassPeriod
  alias Classnavapi.Class.Status
  alias Classnavapi.Student
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Admin.SchoolView

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

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

  def index(conn, params) do
    schools = from(school in School)
    |> filter(params)
    |> Repo.all()
    render(conn, SchoolView, "index.json", schools: schools)
  end

  def show(conn, %{"id" => id}) do
    school = Repo.get!(School, id)
    render(conn, SchoolView, "show.json", school: school)
  end

  def hub(conn, _) do
    student_subquery = from(student in Student)
    student_subquery = student_subquery
              |> group_by([student], student.school_id)
              |> select([student], %{school_id: student.school_id, count: count(student.id)})

    query = from(school in School)
    schools = query
              |> join(:left, [school], student in subquery(student_subquery), student.school_id == school.id)
              |> select([school, student], %{school: school, students: student.count})
              |> Repo.all()
              |> Enum.map(&put_class_statuses(&1))
    
    render(conn, SchoolView, "index.json", schools: schools)
  end

  def update(conn, %{"id" => id} = params) do
    school_old = Repo.get!(School, id)
    
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

  defp filter(query, params) do
    query
    |> short_name_filter(params)
  end

  defp short_name_filter(query, %{"short_name" => short_name}) do
    query
    |> where([school], school.short_name == ^short_name)
  end
  defp short_name_filter(query, _params), do: query

  defp put_class_statuses(%{school: %School{} = school} = params) do
    params
    |> Map.put(:classes, get_class_statuses(school.id))
  end

  defp get_class_statuses(school_id) do
    query = from(class in Class)
    query
        |> join(:inner, [class], prd in ClassPeriod, class.class_period_id == prd.id)
        |> join(:full, [class, prd], status in Status, class.class_status_id == status.id)
        |> where([class, prd], prd.school_id == ^school_id)
        |> group_by([class, prd, status], [status.name])
        |> select([class, prd, status], %{status: status.name, count: count(class.id)})
        |> Repo.all()
  end
end