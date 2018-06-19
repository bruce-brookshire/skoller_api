defmodule Skoller.Class.Change.Type do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Class.Change.Type

  @primary_key {:id, :id, []}
  schema "class_change_types" do
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
