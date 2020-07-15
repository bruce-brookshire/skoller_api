defmodule SkollerWeb.Api.V1.SchoolController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.SchoolView
  alias Skoller.Schools

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200
  @insights_role 700

  plug :verify_role, %{roles: [@admin_role, @student_role, @insights_role]}

  def create(conn, params) do
    case Schools.create_school(params) do
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

  def index(conn, params) do
    schools = Schools.get_schools(params)

    conn
    |> put_view(SchoolView)
    |> render("index.json", schools: schools)
  end
end
