defmodule Classnavapi.Class.Weight do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Weight


  schema "class_weights" do
    field :name, :string
    field :weight, :decimal
    field :class_id, :id
    belongs_to :class, Classnavapi.Class, define_field: false

    timestamps()
  end

  @req_fields [:name, :weight, :class_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Weight{} = weight, attrs) do
    weight
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
