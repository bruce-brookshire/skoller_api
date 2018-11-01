defmodule Skoller.UserRoles do
  @moduledoc """
  A context module for user roles.
  """

  alias Skoller.Repo
  alias Skoller.UserRoles.UserRole

  import Ecto.Query

  @doc """
  Adds a role to a user.
  """
  def add_role(user_id, role_id) do
    UserRole.changeset(%UserRole{}, %{user_id: user_id, role_id: role_id})
    |> Repo.insert()
  end

  @doc """
  Deletes all roles for a user.
  """
  def delete_roles_for_user(user_id) do
    from(role in UserRole)
    |> where([role], role.user_id == ^user_id)
    |> Repo.delete_all()
  end

  @doc """
  Gets all roles for a user.
  """
  def get_roles_for_user(user_id) do
    Repo.all(from ur in UserRole, where: ur.user_id == ^user_id)
  end

  @doc """
  Deletes a single role for a user.
  """
  def delete_role(role) do
    Repo.delete(role)
  end

  def get_role_by_ids!(user_id, role_id) do
    Repo.get_by!(UserRole, user_id: user_id, role_id: role_id)
  end
end