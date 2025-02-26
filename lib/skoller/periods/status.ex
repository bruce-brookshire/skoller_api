defmodule Skoller.Periods.Status do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Periods.Status 

  # The primary key is a normal, non-incrementing ID. Seeded by seed
  # file or migration.
  @primary_key {:id, :id, []}
  schema "class_period_statuses" do
    field :name, :string

    timestamps()
  end

  @req_fields [:id, :name]
  @all_fields @req_fields

  @doc false
  def changeset(%Status{} = status, attrs) do
    status
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
