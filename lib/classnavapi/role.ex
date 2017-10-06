defmodule Classnavapi.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Role


  schema "roles" do
    field :id, :bigserial
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, [:id, :name])
    |> validate_required([:id, :name])
    |> unique_constraint(:name)
  end
end
