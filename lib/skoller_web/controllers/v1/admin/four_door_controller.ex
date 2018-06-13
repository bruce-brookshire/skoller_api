defmodule SkollerWeb.Api.V1.Admin.FourDoorController do
  use SkollerWeb, :controller

  alias Skoller.FourDoor
  alias Skoller.Schools
  alias SkollerWeb.Admin.SchoolView
  alias SkollerWeb.AllView
  alias SkollerWeb.Helpers.RepoHelper

  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    fd = FourDoor.get_default_four_door()
    render(conn, AllView, "show.json", all: fd)
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

  def update(conn, params) do
    case FourDoor.update_four_door_defaults(params) do
      {:ok, _params} ->
        fd = FourDoor.get_default_four_door()
        render(conn, AllView, "show.json", all: fd)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
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