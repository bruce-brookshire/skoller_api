defmodule ClassnavapiWeb.Helpers.ChatPlug do
  
  @moduledoc """
  
  Handles chat auth.

  """

  alias Classnavapi.Repo
  alias Classnavapi.Class
  alias Classnavapi.School
  alias Classnavapi.ClassPeriod

  import Plug.Conn
  import Ecto.Query

  @admin_role 200

  def check_chat_enabled(conn, atom) when is_atom(atom) do
    case conn |> is_admin() do
      true -> conn
      false -> conn |> get_class_enabled(atom)
    end
  end

  def check_chat_enabled(conn, _params) do
    case conn |> is_admin() do
      true -> conn
      false -> conn |> get_class_enabled()
    end
  end

  defp get_class_enabled(conn) do
    status = {:ok, Map.new}
    |> get_class(conn)
    |> get_school_enabled()

    case status do
      {:ok, _val} -> conn
      {:error, _val} -> conn |> unauth()
    end
  end

  defp get_class_enabled(conn, atom) do
    status = {:ok, Map.new}
    |> get_class(conn, atom)
    |> get_school_enabled(atom)

    case status do
      {:ok, _val} -> conn
      {:error, _val} -> conn |> unauth()
    end
  end

  defp get_class({:error, _nil} = map, _conn), do: map
  defp get_class({:ok, map}, conn) do
    case Repo.get(Class, conn.params["class_id"]) do
      %{is_chat_enabled: true} = class -> 
        {:ok, map |> Map.put(:class, class)}
      _ -> {:error, map}
    end
  end
  defp get_class({:ok, map}, conn, :assignment) do
    case Repo.get(Class, conn.params["class_id"]) do
      %{is_assignment_posts_enabled: true} = class -> 
        {:ok, map |> Map.put(:class, class)}
      _ -> {:error, map}
    end
  end

  defp get_school(class_period_id) do
    from(cp in ClassPeriod)
    |> join(:inner, [cp], s in School, s.id == cp.school_id)
    |> where([cp], cp.id == ^class_period_id)
    |> select([cp, s], s)
    |> Repo.one()
  end

  defp get_school_enabled({:error, _nil} = map), do: map
  defp get_school_enabled({:ok, %{class: %{class_period_id: class_period_id}} = map}) do
    case class_period_id |> get_school() do
      %{is_chat_enabled: true} = school -> 
        {:ok, map |> Map.put(:school, school)}
      _ -> 
        {:error, map}
    end
  end
  defp get_school_enabled({:ok, %{class: %{class_period_id: class_period_id}} = map}, :assignment) do
    case class_period_id |> get_school() do
      %{is_assignment_posts_enabled: true} = school -> 
        {:ok, map |> Map.put(:school, school)}
      _ -> 
        {:error, map}
    end
  end

  defp is_admin(conn) do
    Enum.any?(conn.assigns[:user].roles, & &1.id == @admin_role)
  end

  defp unauth(conn) do
    conn
    |> send_resp(403, "")
    |> halt()
  end
end