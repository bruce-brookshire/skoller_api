defmodule Classnavapi.UserRole do

  @moduledoc """

  Defines schema and changeset for user_roles.

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.UserRole


  schema "user_roles" do
    field :user_id, :id
    field :role_id, :id

    timestamps()
  end

  @req_fields [:user_id, :role_id]
  @all_fields @req_fields

  @doc false
  def changeset(%UserRole{} = user_role, attrs) do
    user_role
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:user_role, name: :user_roles_user_id_role_id_index)
  end
end
