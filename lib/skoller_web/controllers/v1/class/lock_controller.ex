defmodule SkollerWeb.Api.V1.Class.LockController do
  @moduledoc """
    Lock controller
  """
  
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias SkollerWeb.Responses.MultiError
  alias SkollerWeb.Class.LockView
  alias Skoller.Classes
  alias Skoller.Locks.Users
  alias Skoller.Locks
  alias Skoller.FourDoor
  alias Skoller.MapErrors
  alias Skoller.Classes.ClassStatuses

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @syllabus_worker_role, @admin_role]}
  plug :verify_member, :class

  @doc """
  Will return a list of locks for a class
  """
  def index(conn, %{"class_id" => class_id}) do
    locks = Users.get_user_locks_by_class(class_id)
    render(conn, LockView, "index.json", locks: locks)
  end

  @doc """
  Locks a class to the current user.

  Returns a 409 when another user has the class locked already unless the user is an admin.
  """
  def lock(%{assigns: %{user: user}} = conn, %{"class_id" => class_id}) do
    case lock_class(user, class_id) do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, _error} ->
        conn
        |> send_resp(409, "")
    end
  end

  @doc """
  Unlocks all locks from the logged in user for a class.
  """
  def unlock(%{assigns: %{user: user}} = conn, %{"class_id" => class_id} = params) do
    old_class = Classes.get_class_by_id(class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:unlock, &unlock_class(user, params, &1))
    |> Ecto.Multi.run(:status, &check_class_status(&1, old_class, params))

    case Repo.transaction(multi) do
      {:ok, %{status: class}} -> 
        ClassStatuses.evaluate_class_completion(old_class, class)
        conn |> send_resp(204, "")
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  defp check_class_status(multi_params, old_class, %{"is_completed" => true}) do
    ClassStatuses.check_status(old_class, multi_params)
  end
  defp check_class_status(_multi_params, _old_class, _params), do: {:ok, nil}

  @doc """
  Locks a class's weights to the current user.

  Returns a 409 when another user has the class locked already unless the user is an admin.
  """
  def weights(%{assigns: %{user: user}} = conn, %{"class_id" => class_id}) do
    case lock_class(user, class_id, :weights) do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, _error} ->
        conn
        |> send_resp(409, "")
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  @doc """
  Locks a class's assignments to the current user.

  Returns a 409 when another user has the class locked already unless the user is an admin.
  """
  def assignments(%{assigns: %{user: user}} = conn, %{"class_id" => class_id}) do
    case lock_class(user, class_id, :assignments) do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, _error} ->
        conn
        |> send_resp(409, "")
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  defp lock_diy(user, class_id, atom) do
    class = Classes.get_class_by_id!(class_id)
            |> Repo.preload(:school)
    
    fd = FourDoor.get_four_door_by_school(class.school.id)

    case fd.is_diy_enabled do
      true -> Locks.lock_class(class_id, user.id, atom)
      false -> {:error, "DIY is not enabled."}
    end
  end

  defp lock_class(%{roles: roles} = user, class_id, atom \\ nil) do
    case Enum.any?(roles, & &1.id == @admin_role) do
      true -> Locks.lock_class(class_id, user.id, nil)
      false -> lock_diy(user, class_id, atom)
    end
  end

  defp unlock_class(user, %{"class_id" => class_id}, _) do
    status = Locks.unlock_locks(class_id, user.id)

    status
    |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
end