defmodule Skoller.Users do
  @moduledoc """
  The Users context.
  """

  alias Skoller.Repo
  alias Skoller.Users.User
  alias Skoller.School.StudentField
  alias Skoller.UserRole
  alias Skoller.Students
  alias SkollerWeb.Helpers.RepoHelper

  import Ecto.Query

  def get_user_by_id!(id) do
    Repo.get!(User, id)
    |> Repo.preload(:student)
  end

  def get_user_by_id(id) do
    Repo.get(User, id)
    |> Repo.preload(:student)
  end

  def create_user(params, opts \\ []) do
    %User{}
    |> User.changeset_insert(params)
    |> verify_student(opts)
    |> insert_user(params)
    |> Repo.transaction()
  end

  def update_user(user_old, params) do
    changeset = User.changeset_update_admin(user_old, params)
    
    Ecto.Multi.new
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.run(:delete_roles, &delete_roles(&1, params))
    |> Ecto.Multi.run(:roles, &add_roles(&1, params))
    |> Ecto.Multi.run(:delete_fields_of_study, &delete_fields_of_study(&1, params))
    |> Ecto.Multi.run(:fields_of_study, &add_fields_of_study(&1, params))
    |> Repo.transaction()
  end

  def get_users_in_class(id) do
    from(u in User)
    |> join(:inner, [u], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.student_id == u.student_id)
    |> where([u, sc], sc.class_id == ^id)
    |> Repo.all()
  end

  defp verify_student(%Ecto.Changeset{valid?: true, changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}} = u_changeset, opts) do
    case opts |> List.keytake(:admin, 0) |> elem(0) do
      {:admin, "true"} -> 
        Ecto.Changeset.change(u_changeset, %{student: Map.put(s_changeset.changes, :is_verified, true)})
      _ -> u_changeset
    end
  end
  defp verify_student(changeset, _opts), do: changeset

  defp insert_user(changeset, params) do
    Ecto.Multi.new
    |> Ecto.Multi.insert(:user, changeset)
    |> Ecto.Multi.run(:roles, &add_roles(&1, params))
    |> Ecto.Multi.run(:fields_of_study, &add_fields_of_study(&1, params))
  end

  defp add_fields_of_study(%{user: user}, %{"student" => %{"fields_of_study" => fields}}) do
    status = fields |> Enum.map(&add_field_of_study(user, &1))

    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp add_fields_of_study(_map, _params), do: {:ok, nil}

  defp add_field_of_study(user, field) do
    Repo.insert!(%StudentField{field_of_study_id: field, student_id: user.student.id})
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
end