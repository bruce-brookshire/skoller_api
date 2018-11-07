defmodule Skoller.UserRoles.UserRole do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.UserRoles.UserRole
  alias Skoller.Users.User
  alias Skoller.Roles.Role

  schema "user_roles" do
    field :user_id, :id
    field :role_id, :id
    belongs_to :user, User, define_field: false
    belongs_to :role, Role, define_field: false

    timestamps()
  end

  @req_fields [:user_id, :role_id]
  @all_fields @req_fields

  @doc false
  def changeset(%UserRole{} = user_role, attrs) do
    user_role
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:role_id)
    |> unique_constraint(:user_role, name: :user_roles_user_id_role_id_index)
  end
end
