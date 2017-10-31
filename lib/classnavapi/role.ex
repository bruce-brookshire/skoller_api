defmodule Classnavapi.Role do

  @moduledoc """
  
  Defines schema and changeset for roles.

  The primary key is not seeded.

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Role

  @primary_key {:id, :id, []}
  schema "roles" do
    field :name, :string

    timestamps()
  end

  @req_fields [:id, :name]
  @all_fields @req_fields

  @doc false
  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:name)
  end
end
