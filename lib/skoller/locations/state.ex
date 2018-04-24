defmodule Skoller.Locations.State do
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Locations.State

  schema "states" do
    field :name, :string
    field :state_code, :string

    timestamps()
  end

  @doc false
  def changeset(%State{} = state, attrs) do
    state
    |> cast(attrs, [:state_code, :name])
    |> validate_required([:state_code, :name])
    |> validate_length(:state_code, is: 2)
  end
end
