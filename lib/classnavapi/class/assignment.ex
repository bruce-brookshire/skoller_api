defmodule Classnavapi.Class.Assignment do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Assignment


  schema "assignments" do
    field :due, :date
    field :name, :string
    field :weight_id, :id
    field :class_id, :id
    belongs_to :class, Classnavapi.Class, define_field: false
    belongs_to :weight, Classnavapi.Class.Weight, define_field: false

    timestamps()
  end

  @req_fields [:due, :name, :class_id, :weight_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Assignment{} = assignment, attrs) do
    assignment
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
