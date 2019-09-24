defmodule Skoller.ChangeRequests.ChangeRequestMember do
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.ChangeRequests.ChangeRequestMember

  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false

  schema "class_change_request_members" do
    field :name, :string
    field :value, :string
    field :class_change_request_id, :id
    field :is_completed, :boolean, default: false

    belongs_to :class_change_request, ChangeRequest, define_field: false

    timestamps()
  end

  @req_fields [:name, :value, :class_change_request_id]
  @opt_fields [:is_completed]
  @all_fields @req_fields ++ @opt_fields

  def changeset(%ChangeRequestMember{} = member, attrs) do
    member
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
