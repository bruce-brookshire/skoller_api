defmodule Classnavapi.Class.Assignment do

  @moduledoc """
  
  Changeset and schema for assignments

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.Weight

  schema "assignments" do
    field :due, :date
    field :name, :string
    field :weight_id, :id
    field :class_id, :id
    field :from_mod, :boolean, default: false
    belongs_to :class, Class, define_field: false
    belongs_to :weight, Weight, define_field: false
    has_many :student_assignments, StudentAssignment

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
