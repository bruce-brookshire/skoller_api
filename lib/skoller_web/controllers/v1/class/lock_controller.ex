defmodule SkollerWeb.Api.V1.Class.LockController do
  @moduledoc """
    Lock controller
  """

  use SkollerWeb, :controller

  alias SkollerWeb.Responses.MultiError
  alias SkollerWeb.Class.LockView
  alias Skoller.Classes
  alias Skoller.Locks.Users
  alias Skoller.Locks
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses
  alias Skoller.Locks.DIY

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  @insights_role 700

  plug :verify_role, %{roles: [@student_role, @syllabus_worker_role, @admin_role, @insights_role]}
  plug :verify_member, :class

  @doc """
  Will return a list of locks for a class
  """
  def index(conn, %{"class_id" => class_id}) do
    locks = Users.get_user_locks_by_class(class_id)

    conn
    |> put_view(LockView)
    |> render("index.json", locks: locks)
  end

  @doc """
  Locks a class to the current user.

  Returns a 409 when another user has the class locked already unless the user is an admin.
  """
  def lock(%{assigns: %{user: user}} = conn, %{"class_id" => class_id}) do
    case lock_class(user, class_id, nil, nil) do
      {:ok, _lock} ->
        conn |> send_resp(204, "")

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
    is_completed = params["is_completed"] == true

    case Locks.unlock_class(old_class, user.id, is_completed) do
      {:ok, %{status: class}} ->
        ClassStatuses.evaluate_class_completion(old_class, class)
        conn |> send_resp(204, "")

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  @doc """
  Locks a class's weights to the current user.

  Returns a 409 when another user has the class locked already unless the user is an admin.
  """
  def weights(%{assigns: %{user: user}} = conn, %{"class_id" => class_id}) do
    case lock_class(user, class_id, :weights, nil) do
      {:ok, _lock} ->
        conn |> send_resp(204, "")

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
  def assignments(%{assigns: %{user: user}} = conn, %{"class_id" => class_id} = params) do
    case lock_class(user, class_id, :assignments, params["subsection"]) do
      {:ok, _lock} ->
        conn |> send_resp(204, "")

      {:error, _error} ->
        conn
        |> send_resp(409, "")

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  defp lock_class(%{roles: roles} = user, class_id, atom, subsection) do
    case Enum.any?(roles, &(&1.id == @student_role)) do
      false -> Locks.lock_class(class_id, user.id, nil)
      true -> DIY.lock_class(user.id, class_id, atom, subsection)
    end
  end
end
