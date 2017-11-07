defmodule Classnavapi.Class.Weight do

  @moduledoc """
  
  Changeset and schema for class_weights

  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Classnavapi.Class.Weight
  alias Classnavapi.Class

  schema "class_weights" do
    field :name, :string
    field :weight, :decimal
    field :class_id, :id
    belongs_to :class, Class, define_field: false

    timestamps()
  end

  @req_fields [:name, :weight]
  @all_fields @req_fields

  @doc false
  def changeset(%Weight{} = weight, attrs) do
    weight
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_number(:weight, greater_than: 0, less_than_or_equal_to: 100)
  end
end
