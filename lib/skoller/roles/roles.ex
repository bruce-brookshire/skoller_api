defmodule Skoller.Roles do
  @moduledoc """
  A context module for roles
  """

  alias Skoller.Roles.Role
  alias Skoller.Repo

  @doc """
  Gets all roles.
  """
  def get_roles() do
    Repo.all(Role)
  end

  @doc """
  Gets a role by id and raises if not found
  """
  def get_role_by_id!(id) do
    Repo.get!(Role, id)
  end
end