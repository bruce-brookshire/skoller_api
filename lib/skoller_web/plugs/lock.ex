defmodule SkollerWeb.Plugs.Lock do

  @moduledoc """

  Handles lock auth.

  """

  alias Skoller.Locks
  alias Skoller.Assignments
  alias Skoller.Weights
  alias Skoller.ClassStatuses.Classes

  import Plug.Conn

  @admin_role 200
  @change_req_role 400
  @help_req_role 500
  @insights_role 700

  @weight_lock 100
  @assignment_lock 200

  def check_lock(conn, params) do
    case conn |> is_admin() do
      true -> conn
      false -> conn |> get_lock(params)
    end
  end

  defp get_lock(%{assigns: %{user: user}} = conn, %{type: :weight, using: :id}) do
    case conn.params |> check_using(:weight, :id) do
      true ->
        weight = Weights.get_weight!(conn.params["id"])
        case Locks.find_lock(weight.class_id, @weight_lock, user.id) do
          [] -> conn |> check_maintenance(weight.class_id)
          _ -> conn
        end
      false -> conn
    end
  end

  defp get_lock(%{assigns: %{user: user}} = conn, %{type: :weight, using: :class_id}) do
    case conn.params |> check_using(:weight, :class_id) do
      true ->
        case Locks.find_lock(conn.params["class_id"], @weight_lock, user.id) do
          [] -> conn |> check_maintenance(conn.params["class_id"])
          _ -> conn
        end
      false -> conn
    end
  end

  defp get_lock(%{assigns: %{user: user}} = conn, %{type: :assignment, using: :id}) do
    case conn.params |> check_using(:assignment, :id) do
      true ->
        assign = Assignments.get_assignment_by_id!(conn.params["id"])
        case Locks.find_lock(assign.class_id, @assignment_lock, user.id, assign.weight_id) do
          [] -> conn |> check_maintenance(assign.class_id)
          _ -> conn
        end
      false -> conn
    end
  end

  defp get_lock(%{assigns: %{user: user}, method: "POST"} = conn, %{type: :assignment, using: :class_id}) do
    case conn.params |> check_using(:assignment, :class_id) do
      true ->
        case Locks.find_lock(conn.params["class_id"], @assignment_lock, user.id, conn.params["weight_id"]) do
          [] -> conn |> check_maintenance(conn.params["class_id"])
          _ -> conn
        end
      false -> conn
    end
  end
  defp get_lock(%{assigns: %{user: user}} = conn, %{type: :assignment, using: :class_id}) do
    case conn.params |> check_using(:assignment, :class_id) do
      true ->
        case Locks.find_lock(conn.params["class_id"], @assignment_lock, user.id) do
          [] -> conn |> check_maintenance(conn.params["class_id"])
          _ -> conn
        end
      false -> conn
    end
  end

  defp check_maintenance(conn, class_id) do
    case Enum.any?(conn.assigns[:user].roles, & &1.id in[@change_req_role, @help_req_role]) do
      true ->
        case Classes.class_in_request?(class_id) do
          true -> conn
          false -> conn |> unauth()
        end
      false -> conn |> unauth()
    end
  end

  defp check_using(%{"id" => nil}, _, :id), do: false
  defp check_using(%{"class_id" => nil}, _, :class_id), do: true
  defp check_using(%{"id" => _}, :weight, :id), do: true
  defp check_using(%{"class_id" => _}, :weight, :class_id), do: true
  defp check_using(%{"id" => _}, :assignment, :id), do: true
  defp check_using(%{"class_id" => _}, :assignment, :class_id), do: true
  defp check_using(_params, _, _), do: false

  defp is_admin(conn) do
    Enum.any?(conn.assigns[:user].roles, & &1.id == @admin_role or &1.id == @insights_role)
  end

  defp unauth(conn) do
    conn
    |> send_resp(403, "")
    |> halt()
  end
end
