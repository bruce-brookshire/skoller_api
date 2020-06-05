defmodule Skoller.Organizations.OrgGroupOwners.OrgGroupOwner do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Organizations.{
    OrgMembers.OrgMember,
    OrgGroups.OrgGroup,
    OrgGroupOwnerWatchlistItems.OrgGroupOwnerWatchlistItem
  }

  schema "org_group_owners" do
    belongs_to :org_group, OrgGroup
    belongs_to :org_member, OrgMember

    has_many :watchlist_items, OrgGroupOwnerWatchlistItem

    timestamps()
  end

  use ExMvc.ModelChangeset, req_fields: ~w[org_group_id org_member_id]a

  def changeset(%__MODULE__{} = struct, params) do
    super(struct, params)
    |> unique_constraint(:org_member_id, name: :org_group_owners_org_member_id_org_group_id_index)
    |> foreign_key_constraint(:org_member_id, name: :org_group_owners_org_member_id_fkey)
    |> foreign_key_constraint(:org_group_id, name: :org_group_owners_org_group_id_fkey)
  end
end
