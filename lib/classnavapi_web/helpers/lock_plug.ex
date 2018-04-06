defmodule ClassnavapiWeb.Helpers.LockPlug do
  
  @moduledoc """
  
  Handles lock auth.

  """

  alias Classnavapi.Repo
  alias Classnavapi.Class.Lock
  alias Classnavapi.Class.Weight
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Universities.Class

  import Plug.Conn
  import Ecto.Query

  @admin_role 200
  @change_req_role 400
  @help_req_role 500

  @weight_lock 100
  @assignment_lock 200
  @review_lock 300

  @help_status 600
  @change_status 800

  def check_lock(conn, params) do
    case conn |> is_admin() do
      true -> conn
      false -> conn |> get_lock(params)
    end
  end

  defp find_lock(class_id, lock, user_id) do
    from(l in Lock)
    |> where([l], l.class_id == ^class_id and l.user_id == ^user_id and l.is_completed == false)
    |> where([l], l.class_lock_section_id in [^lock, @review_lock])
    |> Repo.all()
    |> List.first()
  end

  defp get_lock(%{assigns: %{user: user}} = conn, %{type: :weight, using: :id}) do
    case conn.params |> check_using(:weight, :id) do
      true ->
        weight = Repo.get!(Weight, conn.params["id"])
        case find_lock(weight.class_id, @weight_lock, user.id) do
          nil -> conn |> check_maintenance(weight.class_id)
          _ -> conn
        end
      false -> conn
    end
  end

  defp get_lock(%{assigns: %{user: user}} = conn, %{type: :weight, using: :class_id}) do
    case conn.params |> check_using(:weight, :class_id) do
      true ->
        case find_lock(conn.params["class_id"], @weight_lock, user.id) do
          nil -> conn |> check_maintenance(conn.params["class_id"])
          _ -> conn
        end
      false -> conn
    end
  end

  defp get_lock(%{assigns: %{user: user}} = conn, %{type: :assignment, using: :id}) do
    case conn.params |> check_using(:assignment, :id) do
      true ->
        assign = Repo.get!(Assignment, conn.params["id"])
        case find_lock(assign.class_id, @assignment_lock, user.id) do
          nil -> conn |> check_maintenance(assign.class_id)
          _ -> conn
        end
      false -> conn
    end
  end

  defp get_lock(%{assigns: %{user: user}} = conn, %{type: :assignment, using: :class_id}) do
    case conn.params |> check_using(:assignment, :class_id) do
      true ->
        case find_lock(conn.params["class_id"], @assignment_lock, user.id) do
          nil -> conn |> check_maintenance(conn.params["class_id"])
          _ -> conn
        end
      false -> conn
    end
  end

  defp check_maintenance(conn, class_id) do
    case Enum.any?(conn.assigns[:user].roles, & &1.id in[@change_req_role, @help_req_role]) do
      true -> 
        class = Repo.get!(Class, class_id)
        case class.class_status_id in [@help_status, @change_status] do
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
    Enum.any?(conn.assigns[:user].roles, & &1.id == @admin_role)
  end

  defp unauth(conn) do
    conn
    |> send_resp(403, "")
    |> halt()
  end
end