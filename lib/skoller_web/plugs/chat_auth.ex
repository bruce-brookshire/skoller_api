defmodule SkollerWeb.Plugs.ChatAuth do
  @moduledoc """
  Handles chat auth.
  """

  alias Skoller.Repo
  alias Skoller.Assignments.Assignment
  alias Skoller.Classes
  alias Skoller.Schools

  import Plug.Conn

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
    case Classes.get_class_by_id(conn.params["class_id"]) do
      %{is_chat_enabled: true} = class -> 
        {:ok, map |> Map.put(:class, class)}
      _ -> {:error, map}
    end
  end
  defp get_class({:ok, map}, conn, :assignment) do
    assign = Repo.get!(Assignment, conn.params["assignment_id"])
    case Classes.get_class_by_id(assign.class_id) do
      %{is_assignment_posts_enabled: true} = class -> 
        {:ok, map |> Map.put(:class, class)}
      _ -> {:error, map}
    end
  end

  defp get_school_enabled({:error, _nil} = map), do: map
  defp get_school_enabled({:ok, %{class: %{class_period_id: class_period_id}} = map}) do
    case class_period_id |> Schools.get_school_from_period() do
      %{is_chat_enabled: true} = school -> 
        {:ok, map |> Map.put(:school, school)}
      _ -> 
        {:error, map}
    end
  end
  defp get_school_enabled({:error, _nil} = map, _atom), do: map
  defp get_school_enabled({:ok, %{class: %{class_period_id: class_period_id}} = map}, :assignment) do
    case class_period_id |> Schools.get_school_from_period() do
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