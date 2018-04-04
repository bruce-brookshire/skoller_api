defmodule ClassnavapiWeb.Helpers.AuthPlug do

  @moduledoc """
  
  Handles auth plugs.

  """

  alias Classnavapi.Repo
  alias Classnavapi.Users.User
  alias Classnavapi.Class
  alias Classnavapi.ClassPeriod
  alias Classnavapi.Class.Assignment

  import Plug.Conn

  @student_role 100
  @admin_role 200

  def authenticate(conn, _) do
    case conn |> get_auth_obj() do
      {:ok, user} ->
        assign(conn, :user, user)
      {:error, _} -> conn |> unauth
    end
  end

  def get_auth_obj(%Phoenix.Socket{} = socket) do
    case Repo.get(User, Guardian.Phoenix.Socket.current_resource(socket)) do
      %User{is_active: false} -> {:error, :inactive}
      %User{} = user ->
        user = user |> Repo.preload([:roles, :student])
        {:ok, user}
      nil -> {:error, :no_user}
    end
  end 

  def get_auth_obj(conn) do
    case Repo.get(User, Guardian.Plug.current_resource(conn)) do
      %User{is_active: false} -> {:error, :inactive}
      %User{} = user ->
        user = user |> Repo.preload([:roles, :student])
        {:ok, user}
      nil -> {:error, :no_user}
    end
  end 

  def is_phone_verified(%{assigns: %{user: %{student: nil}}} = conn, _), do: conn
  def is_phone_verified(%{assigns: %{user: %{student: student}}} = conn, _) do
    case List.last(conn.path_info) in ["verify", "resend"] do
      true -> conn
      false -> 
        case student.is_verified do
          true -> conn
          _ -> conn |> unauth
        end
    end
  end
  def is_phone_verified(conn, _), do: conn

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

  def verify_class_is_editable(conn, id) do
    case conn.path_params |> Map.fetch(to_string(id)) do
      :error -> conn
      {:ok, class_id} ->
        case Repo.get_by(Class, id: class_id, is_editable: true) do
          nil -> conn |> in_role(@admin_role)
          _ -> conn
        end
      end
  end

  def verify_member(conn, %{of: type, using: id}) do
    case conn.path_params |> Map.fetch(to_string(id)) do
      :error -> conn
      _ ->
        case conn |> get_items(type) do
          nil -> conn |> not_in_role(@student_role)
          items -> conn |> find_item(%{type: type, items: items, using: id}, conn.path_params)
        end
    end
  end

  def verify_member(conn, atom) do
    case conn |> get_items(atom) do
      nil -> conn |> not_in_role(@student_role)
      items -> conn |> find_item(%{type: atom, items: items}, conn.path_params)
    end
  end

  def verify_user(conn, :allow_admin) do
    case Enum.any?(conn.assigns[:user].roles, & &1.id == @admin_role) do
      true -> conn
      _ ->
        case conn |> get_items(:user) do
          nil -> conn |> unauth
          items -> conn |> find_item(%{type: :user, items: items}, conn.path_params)
        end
    end
  end

  def verify_user(conn, _params) do
    case conn |> get_items(:user) do
      nil -> conn |> unauth
      items -> conn |> find_item(%{type: :user, items: items}, conn.path_params)
    end
  end
  
  def verify_user_exists(%{params: %{"email" => email}} = conn, _) do
    case Repo.get_by(User, email: String.downcase(email)) do
      nil -> conn |> unauth
      _ -> conn
    end
  end
  def verify_user_exists(conn, _), do: conn

  defp not_in_role(conn, role) do
    case Enum.any?(conn.assigns[:user].roles, & &1.id == role) do
      true -> conn |> unauth
      false -> conn
    end
  end

  defp in_role(conn, role) do
    case Enum.any?(conn.assigns[:user].roles, & &1.id == role) do
      false -> conn |> unauth
      true -> conn
    end
  end

  defp get_items(%{assigns: %{user: user}}, :user), do: user.id
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
  defp get_items(%{assigns: %{user: %{student: student}}}, :class_assignment) do
    student = student |> Repo.preload(:classes)
    student.classes
  end

  defp find_item(conn, %{type: :student_assignment, items: assignments, using: :id}, %{"id" => id}) do
    case assignments |> Enum.any?(& &1.id == String.to_integer(id)) do
      true -> conn
      false -> conn |> unauth
    end
  end
  defp find_item(conn, %{type: :class_assignment, items: classes, using: :id}, %{"id" => id}) do
    case Repo.get(Assignment, String.to_integer(id)) do
      nil -> conn |> unauth
      assign -> 
        case classes |> Enum.any?(& &1.id == assign.class_id) do
          true -> conn
          false -> conn |> unauth
        end
    end
  end
  defp find_item(conn, %{type: :student_assignment, items: assignments, using: :assignment_id}, %{"assignment_id" => id}) do
    case assignments |> Enum.any?(& &1.id == String.to_integer(id)) do
      true -> conn
      false -> conn |> unauth
    end
  end
  defp find_item(conn, %{type: :school, items: id, using: :class_id}, %{"class_id" => class_id}) do
    class = Class
            |> Repo.get!(class_id)
            |> Repo.preload(:school)
    case id == class.school.id do
      true -> conn
      false -> conn |> unauth
    end
  end
  defp find_item(conn, %{type: :school, items: id, using: :period_id}, %{"period_id" => period_id}) do
    period = Repo.get!(ClassPeriod, period_id)
    case id == period.school_id do
      true -> conn
      false -> conn |> unauth
    end
  end
  defp find_item(conn, %{type: :class, items: classes, using: :id}, %{"id" => class_id}) do
    conn |> compare_classes(classes, class_id)
  end
  defp find_item(conn, %{type: :class_assignment, items: classes}, %{"assignment_id" => id}) do
    case Repo.get(Assignment, String.to_integer(id)) do
      nil -> conn |> unauth
      assign -> 
        case classes |> Enum.any?(& &1.id == assign.class_id) do
          true -> conn
          false -> conn |> unauth
        end
    end
  end
  defp find_item(conn, %{type: :class, items: classes}, %{"class_id" => class_id}) do
    conn |> compare_classes(classes, class_id)
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
  defp find_item(conn, %{type: :user, items: id}, %{"user_id" => user_id}) do
    case id == String.to_integer(user_id) do
      true -> conn
      false -> conn |> unauth
    end
  end
  defp find_item(conn, _items, _params), do: conn

  defp compare_classes(conn, classes, id) do
    case classes |> Enum.any?(& &1.id == String.to_integer(id)) do
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