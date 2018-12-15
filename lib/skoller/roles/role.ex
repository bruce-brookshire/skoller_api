defmodule Skoller.Roles.Role do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Roles.Role

  # The primary key is a normal, non-incrementing ID. Seeded by seed
  # file or migration.
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
