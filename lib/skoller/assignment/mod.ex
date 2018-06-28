defmodule Skoller.Assignment.Mod do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Assignment.Mod
  alias Skoller.Students.Student
  alias Skoller.Class.Assignment
  alias Skoller.Assignment.Mod.Type
  alias Skoller.Assignment.Mod.Action

  schema "assignment_modifications" do
    field :data, :map
    field :is_private, :boolean, default: false
    field :assignment_id, :id
    field :assignment_mod_type_id, :id
    field :student_id, :id
    field :is_auto_update, :boolean, default: false
    belongs_to :assignment, Assignment, define_field: false
    belongs_to :assignment_mod_type, Type, define_field: false
    belongs_to :student, Student, define_field: false
    has_many :actions, Action, foreign_key: :assignment_modification_id

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
