defmodule Classnavapi.Class.HelpRequest do

  @moduledoc """
  
  Defines the schema and changeset for class_help_requests

  """
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class.HelpRequest

  schema "class_help_requests" do
    field :note, :string
    field :is_completed, :boolean, default: false
    field :class_id, :id
    field :class_help_type_id, :id
    belongs_to :class, Classnavapi.Class, define_field: false
    belongs_to :class_help_type, Classnavapi.Class.Help.Type, define_field: false

    timestamps()
  end

  @req_fields [:class_id, :class_help_type_id]
  @opt_fields [:note, :is_completed]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%HelpRequest{} = issue, attrs) do
    issue
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
