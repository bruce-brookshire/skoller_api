defmodule Skoller.Class.HelpRequest do

  @moduledoc """
  
  Defines the schema and changeset for class_help_requests

  """
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Class.HelpRequest
  alias Skoller.Users.User
  alias Skoller.Schools.Class
  alias Skoller.Class.Help.Type

  schema "class_help_requests" do
    field :note, :string
    field :is_completed, :boolean, default: false
    field :class_id, :id
    field :class_help_type_id, :id
    field :user_id, :id
    belongs_to :class, Class, define_field: false
    belongs_to :class_help_type, Type, define_field: false
    belongs_to :user, User, define_field: false

    timestamps()
  end

  @req_fields [:class_id, :class_help_type_id]
  @opt_fields [:note, :is_completed, :user_id]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%HelpRequest{} = issue, attrs) do
    issue
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
