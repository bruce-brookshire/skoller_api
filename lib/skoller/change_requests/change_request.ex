defmodule Skoller.ChangeRequests.ChangeRequest do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.Schools.Class
  alias Skoller.ChangeRequests.Type
  alias Skoller.Users.User

  schema "class_change_requests" do
    field :is_completed, :boolean, default: false
    field :note, :string
    field :class_id, :id
    field :class_change_type_id, :id
    field :data, :map
    field :user_id, :id
    belongs_to :class, Class, define_field: false
    belongs_to :class_change_type, Type, define_field: false
    belongs_to :user, User, define_field: false

    timestamps()
  end

  @req_fields [:class_id, :class_change_type_id, :data, :user_id]
  @opt_fields [:note, :is_completed]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%ChangeRequest{} = issue, attrs) do
    issue
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:class_change_type_id)
  end
end
