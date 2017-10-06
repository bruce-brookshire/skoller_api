defmodule Classnavapi.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Role

  @primary_key {:id, :integer, []}
  schema "roles" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
