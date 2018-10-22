defmodule Skoller.ClassStatuses.Status do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.ClassStatuses.Status

  # The primary key is a normal, non-incrementing ID. Seeded by seed
  # file or migration.
  @primary_key {:id, :id, []}
  schema "class_statuses" do
    field :is_complete, :boolean, default: false
    field :name, :string
    field :is_maintenance, :boolean, default: false

    timestamps()
  end

  @req_fields [:id, :name, :is_maintenance, :is_complete]
  @all_fields @req_fields

  @doc false
  def changeset(%Status{} = status, attrs) do
    status
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
