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

  def verify_member(conn, %{of: type, using: id}) do
    case conn |> get_items(type) do
      nil -> conn |> not_in_role(@student_role)
      items -> conn |> find_item(%{type: type, items: items, using: id}, conn.params)
    end
  end

  def verify_member(conn, atom) do
    case conn |> get_items(atom) do
      nil -> conn |> not_in_role(@student_role)
      items -> conn |> find_item(%{type: atom, items: items}, conn.params)
    end
  end

  defp not_in_role(conn, role) do
    case Enum.any?(conn.assigns[:user].roles, & &1.id == role) do
      true -> conn |> unauth
      false -> conn
    end
  end

  defp get_items(%{assigns: %{user: %{student: nil}}}, _atom), do: nil
  defp get_items(%{assigns: %{user: %{student: student}}}, :class) do
    student = student |> Repo.preload(:classes)
    student.classes
  end
  defp get_items(%{assigns: %{user: %{student: student}}}, :school), do: student.school_id
  defp get_items(%{assigns: %{user: %{student: student}}}, :student), do: student.id
  defp get_items(%{assigns: %{user: %{student: student}}}, :student_assignment) do
    student = student |> Repo.preload(:student_assignments)
    student.student_assignments
  end

  defp find_item(conn, %{type: :student_assignment, items: assignments, using: :id}, %{"id" => id}) do
    case assignments |> Enum.any?(& &1.id == String.to_integer(id)) do
      true -> conn
      false -> conn |> unauth
    end
  end
  defp find_item(conn, %{type: :class, items: classes}, %{"class_id" => class_id}) do
    case classes |> Enum.any?(& &1.id == String.to_integer(class_id)) do
      true -> conn
      false -> conn |> unauth
    end
  end
  defp find_item(conn, %{type: :school, items: id}, %{"school_id" => school_id}) do
    case id == String.to_integer(school_id) do
      true -> conn
      false -> conn |> unauth
    end
  end
  defp find_item(conn, %{type: :student, items: id}, %{"student_id" => student_id}) do
    case id == String.to_integer(student_id) do
      true -> conn
      false -> conn |> unauth
    end
  end
  defp find_item(conn, _items, _params), do: conn

  defp unauth(conn) do
    conn
    |> send_resp(401, "")
    |> halt()
  end
end