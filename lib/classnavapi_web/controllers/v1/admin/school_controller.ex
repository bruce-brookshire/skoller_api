defmodule ClassnavapiWeb.Api.V1.Admin.SchoolController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Schools.School
  alias Classnavapi.Classes
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Admin.SchoolView
  alias Classnavapi.Students

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
    schools = Students.get_schools_with_enrollment()
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
    |> Map.put(:classes, Classes.get_status_counts(school.id))
  end
end