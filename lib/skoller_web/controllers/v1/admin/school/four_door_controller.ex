defmodule SkollerWeb.Api.V1.Admin.School.FourDoorController do
  use SkollerWeb, :controller

  alias Skoller.FourDoor
  alias Skoller.Schools
  alias SkollerWeb.Admin.SchoolView

  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    schools = FourDoor.get_four_door_overrides()
    render(conn, SchoolView, "index.json", schools: schools)
  end

  def school(conn, %{"school_id" => id} = params) do
    case FourDoor.override_school_four_door(id, params) do
      {:ok, _fd} ->
        s = Schools.get_school_by_id!(id)
        render(conn, SchoolView, "show.json", school: s)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
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
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end