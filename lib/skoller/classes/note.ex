defmodule Skoller.Classes.Note do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Classes.Note

  schema "class_notes" do
    field :notes, :string
    field :class_id, :id

    timestamps()
  end

  @doc false
  def changeset(%Note{} = note, attrs) do
    note
    |> cast(attrs, [:notes])
    |> validate_required([:notes])
  end
end
