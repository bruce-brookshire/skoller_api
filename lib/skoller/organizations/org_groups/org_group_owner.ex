defmodule Skoller.Organizations.OrgGroupOwners.OrgGroupOwner do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Users.User

  alias Skoller.Organizations.{
    OrgGroups.OrgGroup,
    OrgGroupOwnerWatchlistItems.OrgGroupOwnerWatchlistItem
  }

  schema "org_group_owners" do
    belongs_to :org_group, OrgGroup
    belongs_to :user, User

    has_many :watchlist_items, OrgGroupOwnerWatchlistItem
  end

  use ExMvc.ModelChangeset, req_fields: ~w[org_group_id user_id]a
end
