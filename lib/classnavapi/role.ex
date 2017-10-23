defmodule Classnavapi.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Role

  @primary_key {:id, :integer, []}
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
