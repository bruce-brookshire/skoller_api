defmodule SkollerWeb.Api.V1.Admin.SchoolController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Classes
  alias SkollerWeb.Admin.SchoolView
  alias Skoller.Schools
  alias Skoller.EnrolledSchools

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, params) do
    schools = Schools.get_schools(params)
    render(conn, SchoolView, "index.json", schools: schools)
  end

  def show(conn, %{"id" => id}) do
    school = Schools.get_school_by_id!(id)
    render(conn, SchoolView, "show.json", school: school)
  end

  def hub(conn, params) do
    schools = EnrolledSchools.get_schools_with_enrollment(params)
              |> Enum.map(&put_class_statuses(&1))
    
    render(conn, SchoolView, "index.json", schools: schools)
  end

  def update(conn, %{"id" => id} = params) do
    school_old = Schools.get_school_by_id!(id)

    case Schools.update_school(school_old, params) do
      {:ok, school} ->
        render(conn, SchoolView, "show.json", school: school)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp put_class_statuses(%{school: school} = params) do
    params
    |> Map.put(:classes, Classes.get_status_counts(school.id))
  end
end