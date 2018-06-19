defmodule Skoller.Assignment.Mod.Type do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Assignment.Mod.Type

  @primary_key {:id, :id, []}
  schema "assignment_mod_types" do
    field :name, :string

    timestamps()
  end

  @req_fields [:id, :name]
  @all_fields @req_fields

  @doc false
  def changeset(%Type{} = type, attrs) do
    type
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
