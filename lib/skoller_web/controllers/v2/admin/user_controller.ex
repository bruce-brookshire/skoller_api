defmodule SkollerWeb.Api.V2.Admin.UserController do
  use SkollerWeb, :controller

  alias Skoller.Users.User
  alias Skoller.Repo
  alias Skoller.School.StudentField
  alias Skoller.UserRole
  alias SkollerWeb.UserView
  alias SkollerWeb.Helpers.RepoHelper

  import SkollerWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(conn, %{} = params) do
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

  def update(conn, %{"user_id" => user_id} = params) do
    user_old = Repo.get!(User, user_id)
    user_old = user_old |> Repo.preload(:student)
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
