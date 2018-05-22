defmodule Skoller.Users do
  @moduledoc """
  The Users context.
  """

  alias Skoller.Repo
  alias Skoller.Users.User
  alias Skoller.UserRole
  alias Skoller.Students
  alias Skoller.Locks.Lock
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Helpers.VerificationHelper

  import Ecto.Query

  @student_role 100

  def get_user_by_id!(id) do
    Repo.get!(User, id)
    |> Repo.preload([:roles, :student])
  end

  def get_user_by_id(id) do
    Repo.get(User, id)
    |> Repo.preload([:roles, :student])
  end

  def create_user(params, opts \\ []) do
    multi = params
    |> get_changeset()
    |> verify_student(opts)
    |> verification_code(opts)
    |> insert_user(params)
    
    case multi |> Repo.transaction() do
      {:error, _, failed_val, _} ->
        {:error, failed_val}
      {:ok, items} -> {:ok, items}
    end
  end

  def update_user(user_old, params) do
    changeset = User.changeset_update_admin(user_old, params)
    Ecto.Multi.new
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.run(:roles, &add_roles(&1, params))
    |> Ecto.Multi.run(:fields_of_study, &add_fields_of_study(&1, params))
    |> Repo.transaction()
  end

  def get_user_by_email(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  def change_password(user_old, password) do
    user_old
    |> User.changeset_update(%{"password" => password})
    |> Repo.update()
  end

  def get_users_in_class(id) do
    from(u in User)
    |> join(:inner, [u], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.student_id == u.student_id)
    |> where([u, sc], sc.class_id == ^id)
    |> Repo.all()
  end

  def get_user_locks_by_class(class_id) do
    from(l in Lock)
    |> join(:inner, [l], u in User, l.user_id == u.id)
    |> where([l], l.class_id == ^class_id)
    |> select([l, u], %{lock: l, user: u})
    |> Repo.all()
  end

  defp get_changeset(%{"student" => %{"is_university" => true}} = params) do
    %User{}
    |> User.changeset_insert_university(params)
  end
  defp get_changeset(params) do
    %User{}
    |> User.changeset_insert(params)
  end

  defp verification_code(%Ecto.Changeset{valid?: true, changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}} = u_changeset, opts) do
    case get_opt(opts, :admin) do
      "true" -> 
        u_changeset
      _ ->
        Ecto.Changeset.change(u_changeset, %{student: Map.put(s_changeset.changes, :verification_code, VerificationHelper.generate_verify_code)})
    end
  end
  defp verification_code(changeset, _opts), do: changeset

  defp verify_student(%Ecto.Changeset{valid?: true, changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}} = u_changeset, opts) do
    case get_opt(opts, :admin) do
      "true" -> 
        Ecto.Changeset.change(u_changeset, %{student: Map.put(s_changeset.changes, :is_verified, true)})
      _ -> 
        u_changeset
    end
  end
  defp verify_student(changeset, _opts), do: changeset

  defp insert_user(changeset, params) do
    Ecto.Multi.new
    |> Ecto.Multi.insert(:user, changeset)
    |> Ecto.Multi.run(:roles, &add_roles(&1, params))
    |> Ecto.Multi.run(:fields_of_study, &add_fields_of_study(&1, params))
  end

  defp add_fields_of_study(_map, %{"student" => %{"fields_of_study" => nil}}), do: {:ok, nil}
  defp add_fields_of_study(%{user: user}, %{"student" => %{"fields_of_study" => fields}}) do
    delete_fields_of_study(user.student.id)
    status = fields |> Enum.map(&add_field_of_study(user, &1))

    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp add_fields_of_study(_map, _params), do: {:ok, nil}

  defp add_field_of_study(user, field) do
    params = %{field_of_study_id: field, student_id: user.student.id}
    Students.add_field_of_study(params)
  end

  defp add_roles(%{user: user}, params) do
    user 
    |> Repo.preload(:student)
    |> add_roles_preloaded(params)
  end

  defp add_roles_preloaded(%{student: student} = user, _params) when not is_nil(student) do
    user = user |> Repo.preload(:roles)
    case user.roles |> Enum.any?(& &1.id == @student_role) do
      false -> Repo.insert(%UserRole{user_id: user.id, role_id: @student_role})
      true -> {:ok, nil}
    end
  end
  defp add_roles_preloaded(user, %{"roles" => roles}) do
    delete_roles(user.id)
    status = roles
    |> Enum.map(&add_role(user, &1))
    
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp add_roles_preloaded(_map, _params), do: {:ok, nil}

  defp add_role(user, role) do
    Repo.insert!(%UserRole{user_id: user.id, role_id: role})
  end

  defp delete_roles(id) do
    from(role in UserRole)
    |> where([role], role.user_id == ^id)
    |> Repo.delete_all()
  end

  defp delete_fields_of_study(id) do
    Students.delete_fields_of_study_by_student_id(id)
  end

  defp get_opt(opts, atom) do
    case opts |> List.keytake(atom, 0) do
      nil -> nil
      val -> val |> elem(0) |> elem(1)
    end
  end
end