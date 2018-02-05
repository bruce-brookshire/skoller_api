defmodule Classnavapi.Assignment.Mod.Action do

  @moduledoc """
  
  Schema and changeset for mod actions.
  
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Assignment.Mod.Action

  schema "modification_actions" do
    field :is_accepted, :boolean
    field :assignment_modification_id, :id
    field :student_class_id, :id
    field :is_manual, :boolean, default: false

    timestamps()
  end

  @req_fields [:assignment_modification_id, :student_class_id]
  @opt_fields [:is_accepted]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%Action{} = action, attrs) do
    action
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:assignment_modification_id)
    |> foreign_key_constraint(:student_class_id)
    |> unique_constraint(:modification_action, name: :modification_actions_assignment_modification_id_student_class_id_index)
  end
end
