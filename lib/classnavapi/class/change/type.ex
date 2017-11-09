defmodule Classnavapi.Class.Change.Type do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Change.Type


  schema "class_change_types" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Type{} = type, attrs) do
    type
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
