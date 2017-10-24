defmodule Classnavapi.Class.Status do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Status

  @primary_key {:id, :integer, []}
  schema "class_statuses" do
    field :is_complete, :boolean
    field :is_editable, :boolean
    field :name, :string

    timestamps()
  end

  @req_fields [:id, :name, :is_editable, :is_complete]
  @all_fields @req_fields

  @doc false
  def changeset(%Status{} = status, attrs) do
    status
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
