defmodule Skoller.ChangeRequests.ChangeRequestMember do

  alias Skoller.ChangeRequests.ChangeRequest

  use Ecto.Schema
  import Ecto.Changeset
  

  schema "class_change_request_members" do
    field :name, :string
    field :value, :string
    field :class_change_request_id, :id
    field :is_completed, :boolean, default: false

    belongs_to :change_request, ChangeRequest, define_field: false
  end

  @req_fields [:name, :value, :change_request_id]
  @opt_fields [:is_completed]
  @all_fields @req_fields ++ @opt_fields

  @upd_req [:is_completed]
  @upd_fields @upd_req

  @doc false
  def changeset(%ChangeRequestMember{} = member, attrs) do
    member
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end

  def changeset_update(%ChangeRequestMember{} = member, attrs) do
    member
    |> cast(attrs, @upd_fields)
    |> validate_required(@upd_req)
  end
end