defmodule Skoller.Class.Weight do

  @moduledoc """
  
  Changeset and schema for class_weights

  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Class.Weight
  alias Skoller.Schools.Class

  schema "class_weights" do
    field :name, :string
    field :weight, :decimal
    field :class_id, :id
    belongs_to :class, Class, define_field: false

    timestamps()
  end

  @req_fields [:name, :weight]
  @all_fields @req_fields

  @adm_req @req_fields ++ [:class_id]
  @all_adm @adm_req

  @doc false
  def changeset(%Weight{} = weight, attrs) do
    weight
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_number(:weight, greater_than: 0)
  end

  def changeset_admin(%Weight{} = weight, attrs) do
    weight
    |> cast(attrs, @all_adm)
    |> validate_required(@adm_req)
    |> validate_number(:weight, greater_than: 0)
    |> foreign_key_constraint(:class_id)
  end
end
