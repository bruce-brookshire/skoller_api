defmodule Classnavapi.UserRole do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.UserRole


  schema "user_roles" do
    field :user_id, :id
    field :role_id, :id

    timestamps()
  end

  @doc false
  def changeset(%UserRole{} = user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
    |> unique_constraint(:user_role, name: :user_roles_user_id_role_id_index)
  end
end
