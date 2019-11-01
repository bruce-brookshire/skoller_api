defmodule Skoller.ChangeRequests.ChangeRequest do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.ChangeRequests.ChangeRequestMember
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.ChangeRequests.Type
  alias Skoller.Classes.Class
  alias Skoller.Users.User

  schema "class_change_requests" do
    field :note, :string
    field :class_id, :id
    field :class_change_type_id, :id
    field :user_id, :id
    belongs_to :class, Class, define_field: false
    belongs_to :class_change_type, Type, define_field: false
    belongs_to :user, User, define_field: false

    has_many :class_change_request_members, ChangeRequestMember,
      foreign_key: :class_change_request_id

    timestamps()
  end

  @req_fields [:class_id, :class_change_type_id, :user_id]
  @opt_fields [:note]
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

# TODO remove this after we are certain migration is good
defmodule Skoller.ChangeRequests.ChangeRequestDeprecated do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.ChangeRequests.ChangeRequestDeprecated
  alias Skoller.ChangeRequests.ChangeRequestMember
  alias Skoller.ChangeRequests.Type
  alias Skoller.Classes.Class
  alias Skoller.Users.User

  schema "class_change_requests" do

    field :note, :string
    field :class_id, :id
    field :class_change_type_id, :id
    
    field :data, :map
    field :is_completed, :boolean, default: false

    field :user_id, :id
    belongs_to :class, Class, define_field: false
    belongs_to :class_change_type, Type, define_field: false
    belongs_to :user, User, define_field: false

    has_many :class_change_request_members, ChangeRequestMember,
      foreign_key: :class_change_request_id

    timestamps()
  end

  @req_fields [:class_id, :class_change_type_id, :user_id]
  @opt_fields [:note, :data, :is_completed]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%ChangeRequestDeprecated{} = issue, attrs) do
    issue
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:class_change_type_id)
  end
end
