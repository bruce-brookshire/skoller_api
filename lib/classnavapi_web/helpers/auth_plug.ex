defmodule ClassnavapiWeb.Helpers.AuthPlug do

  alias Classnavapi.Repo
  alias Classnavapi.User

  import Plug.Conn

  @student_role 100

  def authenticate(conn, _) do
    case Repo.get(User, Guardian.Plug.current_resource(conn)) do
      %User{} = user ->
        user = user |> Repo.preload([:roles, :student])
        assign(conn, :user, user)
      nil -> conn |> unauth
    end
  end

  def verify_role(conn, %{role: role}) do
    case Enum.any?(conn.assigns[:user].roles, & &1.id == role) do
      true -> conn
      false -> conn |> unauth
    end
  end

  def verify_role(conn, %{roles: role}) do
    case Enum.any?(conn.assigns[:user].roles, &Enum.any?(role, fn x -> &1.id == x end)) do
      true -> conn
      false -> conn |> unauth
    end
  end

  def verify_member(conn, :class) do
    case conn |> get_classes() do
      nil -> conn |> not_in_role(@student_role)
      classes -> conn |> find_class(classes, conn.params)
    end
  end

  def verify_member(conn, :school) do
    case conn |> get_school() do
      nil -> conn |> not_in_role(@student_role)
      school_id -> conn |> find_school(school_id, conn.params)
    end
  end

  defp not_in_role(conn, role) do
    case Enum.any?(conn.assigns[:user].roles, & &1.id == role) do
      true -> conn |> unauth
      false -> conn
    end
  end

  defp get_classes(%{assigns: %{user: %{student: nil}}}), do: nil
  defp get_classes(%{assigns: %{user: %{student: student}}}) do
    student = student |> Repo.preload(:classes)
    student.classes
  end

  defp get_school(%{assigns: %{user: %{student: nil}}}), do: nil
  defp get_school(%{assigns: %{user: %{student: student}}}), do: student.school_id

  defp find_class(conn, classes, %{"class_id" => class_id}) do
    case classes |> Enum.any?(& &1.id == String.to_integer(class_id)) do
      true -> conn
      false -> conn |> unauth
    end
  end

  defp find_school(conn, id, %{"school_id" => school_id}) do
    case id == String.to_integer(school_id) do
      true -> conn
      false -> conn |> unauth
    end
  end

  defp unauth(conn) do
    conn
    |> send_resp(401, "")
    |> halt()
  end
end