defmodule SkollerWeb.Plugs.Auth do
  @moduledoc """
  Handles auth plugs.
  """

  alias Skoller.Repo
  alias Skoller.Users
  alias Skoller.Students
  alias Skoller.Assignments
  alias Skoller.EnrolledStudents
  alias Skoller.Classes.EditableClasses
  alias Skoller.SkollerJobs.JobProfiles
  alias Skoller.SkollerJobs.CareerActivities
  alias Skoller.SkollerJobs.JobProfiles.JobProfile
  alias Skoller.SkollerJobs.CareerActivity

  import Plug.Conn

  @student_role 100
  @admin_role 200

  @job_g8_token "Bearer " <> System.get_env("JOBG8_ACCESS_TOKEN")

  def authenticate(conn, _) do
    case conn |> get_auth_obj() do
      {:ok, user} ->
        assign(conn, :user, user)

      {:error, :inactive} ->
        conn |> forbidden

      {:error, _} ->
        conn |> unauth
    end
  end

  def get_auth_obj(%Phoenix.Socket{} = socket) do
    case Users.get_user_by_id(Guardian.Phoenix.Socket.current_resource(socket)) do
      %{is_active: false} -> {:error, :inactive}
      nil -> {:error, :no_user}
      %{} = user -> {:ok, user}
    end
  end

  def get_auth_obj(conn) do
    case Users.get_user_by_id(Guardian.Plug.current_resource(conn)) do
      %{is_active: false} ->
        {:error, :inactive}

      nil ->
        {:error, :no_user}

      %{} = user ->
        {:ok, user}
    end
  end

  def verify_role(conn, %{role: role}) do
    case Enum.any?(conn.assigns[:user].roles, &(&1.id == role)) do
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
      :error ->
        conn

      {:ok, class_id} ->
        case EditableClasses.get_editable_class_by_id(class_id) do
          nil -> conn |> in_role(@admin_role)
          _ -> conn
        end
    end
  end

  def verify_member(conn, %{of: type, using: id}) do
    case conn.path_params |> Map.fetch(to_string(id)) do
      :error ->
        conn

      _ ->
        case conn |> get_items(type) do
          nil -> conn |> not_in_role(@student_role)
          items -> conn |> find_item(%{type: type, items: items, using: id}, conn.path_params)
        end
    end
  end

  def verify_member(
        %{assigns: %{profile: %{id: profile_id}}, path_params: %{"activity_id" => activity_id}} =
          conn,
        :job_activity
      ) do
    case CareerActivities.get_by_id(activity_id) do
      %CareerActivity{job_profile_id: parent_profile_id} when profile_id == parent_profile_id ->
        conn

      _ ->
        conn |> unauth
    end
  end

  def verify_member(conn, atom) do
    case conn |> get_items(atom) do
      nil -> conn |> not_in_role(@student_role)
      items -> conn |> find_item(%{type: atom, items: items}, conn.path_params)
    end
  end

  def verify_user(conn, :allow_admin) do
    case Enum.any?(conn.assigns[:user].roles, &(&1.id == @admin_role)) do
      true ->
        conn

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
    case Users.get_user_by_email(email) do
      nil -> conn |> unauth
      _ -> conn
    end
  end

  def verify_user_exists(conn, _), do: conn

  def verify_student_exists(%{params: %{"phone" => phone}} = conn, _) do
    case Students.get_student_by_phone(phone) do
      nil -> conn |> unauth
      _ -> conn
    end
  end

  def verify_student_exists(conn, _), do: conn

  def verify_owner(
        %{params: %{"profile_id" => id}, assigns: %{user: %{id: user_id}}} = conn,
        :jobs_profile
      ) do
    case JobProfiles.get_by_id_and_user_id(id, user_id) do
      %JobProfile{} = profile -> assign(conn, :profile, profile)
      _ -> conn |> unauth
    end
  end

  def verify_owner(
        %{params: %{"id" => id}, assigns: %{user: %{id: user_id}}} = conn,
        :jobs_profile
      ) do
    case JobProfiles.get_by_id_and_user_id(id, user_id) do
      %JobProfile{} = profile -> assign(conn, :profile, profile)
      _ -> conn |> unauth
    end
  end

  def verify_owner(conn, :jobs_profile), do: conn |> unauth

  def verify_owner(%{assigns: %{user: user}} = conn, :with_jobs_profile) do
    case Repo.preload(user, [:job_profile]) do
      %{job_profile: profile} = new_user when not is_nil(profile) ->
        conn |> assign(:user, new_user)

      _ ->
        unauth(conn)
    end
  end

  def verify_jobg8_connection(%{req_headers: headers} = conn, _) do
    proper_auth_header = {"authorization", @job_g8_token}

    case Enum.find(headers, &(&1 == proper_auth_header)) do
      nil -> unauth(conn)
      _ -> conn
    end
  end

  defp not_in_role(conn, role) do
    case Enum.any?(conn.assigns[:user].roles, &(&1.id == role)) do
      true -> conn |> unauth
      false -> conn
    end
  end

  defp in_role(conn, role) do
    case Enum.any?(conn.assigns[:user].roles, &(&1.id == role)) do
      false -> conn |> unauth
      true -> conn
    end
  end

  defp get_items(%{assigns: %{user: user}}, :user), do: user.id
  defp get_items(%{assigns: %{user: %{student: nil}}}, _atom), do: nil

  defp get_items(%{assigns: %{user: %{student: student}}}, :class) do
    student =
      student |> Repo.preload(classes: EnrolledStudents.preload_enrolled_classes(student.id))

    student.classes
  end

  defp get_items(%{assigns: %{user: %{student: student}}}, :student), do: student.id

  defp get_items(%{assigns: %{user: %{student: student}}}, :student_assignment) do
    student = student |> Repo.preload(:student_assignments)
    student.student_assignments
  end

  defp get_items(%{assigns: %{user: %{student: student}}}, :class_assignment) do
    student =
      student |> Repo.preload(classes: EnrolledStudents.preload_enrolled_classes(student.id))

    student.classes
  end

  defp find_item(conn, %{type: :student_assignment, items: assignments, using: :id}, %{"id" => id}) do
    case assignments |> Enum.any?(&(&1.id == String.to_integer(id))) do
      true -> conn
      false -> conn |> unauth
    end
  end

  defp find_item(conn, %{type: :class_assignment, items: classes, using: :id}, %{"id" => id}) do
    case Assignments.get_assignment_by_id(String.to_integer(id)) do
      nil ->
        conn |> unauth

      assign ->
        case classes |> Enum.any?(&(&1.id == assign.class_id)) do
          true -> conn
          false -> conn |> unauth
        end
    end
  end

  defp find_item(conn, %{type: :student_assignment, items: assignments, using: :assignment_id}, %{
         "assignment_id" => id
       }) do
    case assignments |> Enum.any?(&(&1.id == String.to_integer(id))) do
      true -> conn
      false -> conn |> unauth
    end
  end

  defp find_item(conn, %{type: :class, items: classes, using: :id}, %{"id" => class_id}) do
    conn |> compare_classes(classes, class_id)
  end

  defp find_item(conn, %{type: :class_assignment, items: classes}, %{"assignment_id" => id}) do
    case Assignments.get_assignment_by_id(String.to_integer(id)) do
      nil ->
        conn |> unauth

      assign ->
        case classes |> Enum.any?(&(&1.id == assign.class_id)) do
          true -> conn
          false -> conn |> unauth
        end
    end
  end

  defp find_item(conn, %{type: :class, items: classes}, %{"class_id" => class_id}) do
    conn |> compare_classes(classes, class_id)
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
    case classes |> Enum.any?(&(&1.id == String.to_integer(id))) do
      true -> conn
      false -> conn |> unauth
    end
  end

  defp unauth(conn) do
    conn
    |> send_resp(401, "")
    |> halt()
  end

  defp forbidden(conn) do
    conn
    |> send_resp(403, "")
    |> halt()
  end
end
