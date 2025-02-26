defmodule Skoller.HelpRequests.Type do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.HelpRequests.Type

  # The primary key is a normal, non-incrementing ID. Seeded by seed
  # file or migration.
  @primary_key {:id, :id, []}
  schema "class_help_types" do
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
