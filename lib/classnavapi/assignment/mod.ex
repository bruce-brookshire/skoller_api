defmodule Classnavapi.Assignment.Mod do

  @moduledoc """
  
  Schema and changeset for mods.
  
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Assignment.Mod

  schema "assignment_modifications" do
    field :data, :map
    field :is_private, :boolean, default: false
    field :assignment_id, :id
    field :assignment_mod_type_id, :id
    field :student_id, :id
    belongs_to :assignment, Classnavapi.Class.Assignment, define_field: false
    belongs_to :assignment_mod_type, Classnavapi.Assignment.Mod.Type, define_field: false
    belongs_to :student, Classnavapi.Student, define_field: false

    timestamps()
  end

  @req_fields [:data, :is_private, :student_id, :assignment_id, :assignment_mod_type_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Mod{} = mod, attrs) do
    mod
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:assignment_id)
    |> foreign_key_constraint(:assignment_mod_type_id)
  end
end
