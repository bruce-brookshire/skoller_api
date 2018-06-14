defmodule SkollerWeb.Api.V1.Class.LockController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Class.LockView
  alias Skoller.Classes
  alias Skoller.Users
  alias Skoller.Locks
  alias Skoller.FourDoor

  import SkollerWeb.Helpers.AuthPlug

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @syllabus_worker_role, @admin_role]}
  plug :verify_member, :class

  def index(conn, %{"class_id" => class_id}) do
    locks = Users.get_user_locks_by_class(class_id)

    render(conn, LockView, "index.json", locks: locks)
  end

  def lock(%{assigns: %{user: %{roles: roles}}} = conn, params) do
    case Enum.any?(roles, & &1.id == @admin_role) do
      true -> lock_admin(conn, params)
      false -> lock_diy(conn, params)
    end
  end

  def unlock(%{assigns: %{user: user}} = conn, params) do
    old_class = Classes.get_class_by_id(params["class_id"])

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:unlock, &unlock_class(user, params, &1))
    |> Ecto.Multi.run(:status, &Classes.check_status(old_class, &1))

    case Repo.transaction(multi) do
      {:ok, %{status: class}} -> 
        Classes.evaluate_class_completion(old_class, class)
        conn |> send_resp(204, "")
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp lock_admin(%{assigns: %{user: user}} = conn, params) do
    Locks.lock_class(params["class_id"], user.id)

    conn |> send_resp(204, "")
  end

  defp lock_diy(%{assigns: %{user: user}} = conn, %{"class_id" => class_id} = params) do
    class = Classes.get_class_by_id!(class_id)
            |> Repo.preload(:school)
    
    fd = FourDoor.get_four_door_by_school(class.school.id)

    case fd.is_diy_enabled do
      true -> conn |> lock_full_class(user, params)
      false -> conn |> send_resp(401, "")
    end
  end

  defp lock_full_class(conn, user, params) do
    status = Locks.lock_class(params["class_id"], user.id)
    case status do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, _error} ->
        conn
        |> send_resp(409, "")
    end
  end

  defp unlock_class(user, %{"class_id" => class_id} = params, _) do
    status = Locks.unlock_locks(class_id, user.id, params)

    status
    |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
end