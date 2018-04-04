defmodule ClassnavapiWeb.Api.V1.Admin.UserController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Users.User
  alias Classnavapi.Repo
  alias Classnavapi.School.StudentField
  alias Classnavapi.UserRole
  alias ClassnavapiWeb.UserView
  alias ClassnavapiWeb.UserListView
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias Classnavapi.Student
  alias Classnavapi.School
  alias Classnavapi.Users

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role "100"
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(conn, %{} = params) do
    params = params |> Map.put("student", params["student"] |> Users.put_future_reminder_notification_time())
    changeset = User.changeset_insert(%User{}, params)

    multi = changeset 
    |> verify_student()
    |> insert_user(params)
    
    case Repo.transaction(multi) do
      {:ok, %{user: user}} ->
        render(conn, UserView, "show.json", user: user)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def index(conn, params) do
    users = from(user in User)
    |> join(:inner, [user], role in UserRole, role.user_id == user.id)
    |> join(:left, [user, role], student in Student, student.id == user.student_id)
    |> join(:left, [user, role, student], school in School, school.id == student.school_id)
    |> where([user, role, student, school], ^filters(params))
    |> distinct([user, role, student, school], user.id)
    |> select([user, role, student, school], %{user: user, student: student})
    |> Repo.all()
    render(conn, UserListView, "index.json", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get!(User, id)
      render(conn, UserView, "show.json", user: user)
  end

  def update(conn, %{"user_id" => user_id} = params) do
    user_old = Repo.get!(User, user_id)
    user_old = user_old |> Repo.preload(:student)
    params = params |> Map.put("student", params["student"] |> Users.put_future_reminder_notification_time())
    changeset = User.changeset_update_admin(user_old, params)
    
    multi = Ecto.Multi.new
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.run(:delete_roles, &delete_roles(&1, params))
    |> Ecto.Multi.run(:roles, &add_roles(&1, params))
    |> Ecto.Multi.run(:delete_fields_of_study, &delete_fields_of_study(&1, params))
    |> Ecto.Multi.run(:fields_of_study, &add_fields_of_study(&1, params))

    case Repo.transaction(multi) do
      {:ok, %{user: user}} ->
        render(conn, UserView, "show.json", user: user)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp filters(params) do
    dynamic = params["or"] != "true"

    dynamic
    |> name_filter(params)
    |> email_filter(params)
    |> account_type_filter(params)
    |> school_filter(params)
    |> suspended_filter(params)
  end

  defp account_type_filter(dynamic, %{"account_type" => filter}) do
    dynamic([user, role, student, school], role.role_id == ^filter and ^dynamic)
  end
  defp account_type_filter(dynamic, _params), do: dynamic

  defp school_filter(dynamic, %{"account_type" => @student_role, "school_id" => filter}) do
    dynamic([user, role, student, school], school.id == ^filter and ^dynamic)
  end
  defp school_filter(dynamic, _params), do: dynamic

  defp name_filter(dynamic, %{"account_type" => @student_role, "user_name" => filter, "or" => "true"}) do
    filter = "%" <> filter <> "%"
    dynamic([user, role, student, school], (ilike(student.name_first, ^filter) or ilike(student.name_last, ^filter)) or ^dynamic)
  end
  defp name_filter(dynamic, %{"account_type" => @student_role, "user_name" => filter}) do
    filter = "%" <> filter <> "%"
    dynamic([user, role, student, school], (ilike(student.name_first, ^filter) or ilike(student.name_last, ^filter)) and ^dynamic)
  end
  defp name_filter(dynamic, _params), do: dynamic

  defp email_filter(dynamic, %{"email" => filter, "or" => "true"}) do
    filter = "%" <> filter <> "%"
    dynamic([user, role, student, school], ilike(user.email, ^filter) or ^dynamic)
  end
  defp email_filter(dynamic, %{"email" => filter}) do
    filter = "%" <> filter <> "%"
    dynamic([user, role, student, school], ilike(user.email, ^filter) and ^dynamic)
  end
  defp email_filter(dynamic, _params), do: dynamic

  defp suspended_filter(dynamic, %{"is_suspended" => "true"}) do
    dynamic([user, role, student, school], user.is_active == false and ^dynamic)
  end
  defp suspended_filter(dynamic, %{"is_suspended" => "false"}) do
    dynamic([user, role, student, school], user.is_active == true and ^dynamic)
  end
  defp suspended_filter(dynamic, _params), do: dynamic

  defp delete_roles(%{user: user}, _params) do
    from(role in UserRole)
    |> where([role], role.user_id == ^user.id)
    |> Repo.delete_all()
    {:ok, nil}
  end

  defp delete_fields_of_study(%{user: %{student: nil}}, _params), do: {:ok, nil}
  defp delete_fields_of_study(%{user: %{student: _student}}, %{"student" => %{"fields_of_study" => nil}}), do: {:ok, nil}
  defp delete_fields_of_study(%{user: %{student: student}}, %{"student" => %{"fields_of_study" => _fields}}) do
    from(sf in StudentField)
    |> where([sf], sf.student_id == ^student.id)
    |> Repo.delete_all()
    {:ok, nil}
  end
  defp delete_fields_of_study(%{user: %{student: _student}}, _params), do: {:ok, nil}

  defp add_fields_of_study(%{user: user}, %{"student" => %{"fields_of_study" => fields}}) do
    status = fields |> Enum.map(&add_field_of_study(user, &1))

    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp add_fields_of_study(_map, _params), do: {:ok, nil}

  defp add_field_of_study(user, field) do
    Repo.insert!(%StudentField{field_of_study_id: field, student_id: user.student.id})
  end

  defp verify_student(%Ecto.Changeset{valid?: true, changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}} = u_changeset) do
    Ecto.Changeset.change(u_changeset, %{student: Map.put(s_changeset.changes, :is_verified, true)})
  end
  defp verify_student(changeset), do: changeset

  defp insert_user(changeset, params) do
    Ecto.Multi.new
    |> Ecto.Multi.insert(:user, changeset)
    |> Ecto.Multi.run(:roles, &add_roles(&1, params))
    |> Ecto.Multi.run(:fields_of_study, &add_fields_of_study(&1, params))
  end

  defp add_roles(%{user: user}, %{"roles" => roles}) do
    status = roles
    |> Enum.map(&add_role(user, &1))
    
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp add_roles(_map, _params), do: {:ok, nil}

  defp add_role(user, role) do
    Repo.insert!(%UserRole{user_id: user.id, role_id: role})
  end
end
