defmodule SkollerWeb.Api.V1.Admin.School.FourDoorController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.FourDoor
  alias Skoller.Schools
  alias SkollerWeb.Admin.SchoolView

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    schools = FourDoor.get_four_door_overrides()

    conn
    |> put_view(SchoolView)
    |> render("index.json", schools: schools)
  end

  def school(conn, %{"school_id" => id, "settings" => params}) do
    case FourDoor.override_school_four_door(id, params) do
      {:ok, _fd} ->
        s = Schools.get_school_by_id!(id)

        conn
        |> put_view(SchoolView)
        |> render("show.json", school: s)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"school_id" => id}) do
    case FourDoor.delete_override(id) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
