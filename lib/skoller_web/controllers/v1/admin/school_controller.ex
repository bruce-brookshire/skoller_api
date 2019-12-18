defmodule SkollerWeb.Api.V1.Admin.SchoolController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Admin.SchoolView
  alias Skoller.Schools
  alias Skoller.EnrolledSchools

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def index(conn, params) do
    schools = Schools.get_schools(params)

    conn
    |> put_view(SchoolView)
    |> render("index.json", schools: schools)
  end

  def show(conn, %{"id" => id}) do
    school = Schools.get_school_by_id!(id)

    conn
    |> put_view(SchoolView)
    |> render("show.json", school: school)
  end

  def hub(conn, params) do
    schools = EnrolledSchools.get_schools_with_enrollment(params)

    conn
    |> put_view(SchoolView)
    |> render("index.json", schools: schools)
  end

  def update(conn, %{"id" => id} = params) do
    school_old = Schools.get_school_by_id!(id)

    case Schools.update_school(school_old, params, admin: true) do
      {:ok, school} ->
        conn
        |> put_view(SchoolView)
        |> render("show.json", school: school)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
