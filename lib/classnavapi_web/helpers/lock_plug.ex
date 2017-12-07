defmodule ClassnavapiWeb.Helpers.LockPlug do
  
  @moduledoc """
  
  Handles auth plugs.

  """

  alias Classnavapi.Repo
  alias Classnavapi.Class.Lock
  alias Classnavapi.Class.Weight

  import Plug.Conn

  @admin_role 200

  @weight_lock 100

  def check_lock(conn, params) do
    case conn |> is_admin() do
      true -> conn
      false -> conn |> get_lock(params)
    end
  end

  defp get_lock(%{assigns: %{user: user}} = conn, %{type: :weight, using: :id}) do
    case conn.params |> check_using(:weight) do
      true ->
        weight = Repo.get!(Weight, conn.params["id"])
        case Repo.get_by(Lock, class_id: weight.class_id, class_lock_section_id: @weight_lock, user_id: user.id, is_completed: false) do
          nil -> conn |> unauth
          _ -> conn
        end
      false -> conn
    end
  end

  defp check_using(%{"id" => _}, :weight), do: true
  defp check_using(_params, _), do: false

  defp is_admin(conn) do
    Enum.any?(conn.assigns[:user].roles, & &1.id == @admin_role)
  end

  defp unauth(conn) do
    conn
    |> send_resp(401, "")
    |> halt()
  end
end