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
    field :data, :map
    field :user_id, :id
    belongs_to :class, Classnavapi.Class, define_field: false
    belongs_to :class_change_type, Classnavapi.Class.Change.Type, define_field: false
    belongs_to :users, Classnavapi.User, define_field: false

    timestamps()
  end

  @req_fields [:class_id, :class_change_type_id]
  @opt_fields [:note, :is_completed, :data, :user_id]
  @all_fields @req_fields ++ @opt_fields

  @v2req_fields [:class_id, :class_change_type_id, :data, :user_id]
  @v2opt_fields [:note, :is_completed]
  @v2all_fields @v2req_fields ++ @v2opt_fields

  @doc false
  def changeset(%ChangeRequest{} = issue, attrs) do
    issue
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:class_change_type_id)
  end

  def v2changeset(%ChangeRequest{} = issue, attrs) do
    issue
    |> cast(attrs, @v2all_fields)
    |> validate_required(@v2req_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:class_change_type_id)
  end
end
