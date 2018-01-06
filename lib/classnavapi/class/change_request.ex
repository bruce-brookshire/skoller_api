defmodule Classnavapi.Class.ChangeRequest do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.ChangeRequest

  @moduledoc """
  
  Schema and changeset for class change requests.

  """

  schema "class_change_requests" do
    field :is_completed, :boolean, default: false
    field :note, :string
    field :class_id, :id
    field :class_change_type_id, :id
    belongs_to :class, Classnavapi.Class, define_field: false
    belongs_to :class_change_type, Classnavapi.Class.Change.Type, define_field: false

    timestamps()
  end

  @req_fields [:class_id, :class_change_type_id]
  @opt_fields [:note, :is_completed]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%ChangeRequest{} = issue, attrs) do
    issue
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
