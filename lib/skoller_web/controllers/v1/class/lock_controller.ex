defmodule SkollerWeb.Api.V1.Class.LockController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias SkollerWeb.Responses.MultiError
  alias SkollerWeb.Class.LockView
  alias Skoller.Classes
  alias Skoller.Users
  alias Skoller.Locks
  alias Skoller.FourDoor
  alias Skoller.MapErrors

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @syllabus_worker_role, @admin_role]}
  plug :verify_member, :class

  def index(conn, %{"class_id" => class_id}) do
    locks = Users.get_user_locks_by_class(class_id)
    render(conn, LockView, "index.json", locks: locks)
  end

  def lock(%{assigns: %{user: %{roles: roles} = user}} = conn, %{"class_id" => class_id}) do
    lock = case Enum.any?(roles, & &1.id == @admin_role) do
      true -> Locks.lock_class(class_id, user.id)
      false -> lock_diy(user, class_id)
    end
    case lock do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, _error} ->
        conn
        |> send_resp(409, "")
    end
  end

  def unlock(%{assigns: %{user: user}} = conn, %{"class_id" => class_id}) do
    old_class = Classes.get_class_by_id(class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:unlock, &unlock_class(user, params, &1))
    |> Ecto.Multi.run(:status, &Classes.check_status(old_class, &1))

    case Repo.transaction(multi) do
      {:ok, %{status: class}} -> 
        Classes.evaluate_class_completion(old_class, class)
        conn |> send_resp(204, "")
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def weights(conn, params) do
    
  end

  def assignments(conn, params) do
    
  end

  defp lock_diy(user, class_id) do
    class = Classes.get_class_by_id!(class_id)
            |> Repo.preload(:school)
    
    fd = FourDoor.get_four_door_by_school(class.school.id)

    case fd.is_diy_enabled do
      true -> Locks.lock_class(class_id, user.id)
      false -> {:error, "DIY is not enabled."}
    end
  end

  defp unlock_class(user, %{"class_id" => class_id} = params, _) do
    status = Locks.unlock_locks(class_id, user.id, params)

    status
    |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
end