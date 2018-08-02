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

  @req_fields [:notes, :class_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Note{} = note, attrs) do
    note
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
