defmodule Skoller.Organizations.OrgGroupOwners.OrgGroupOwner do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Users.User
  alias Skoller.Organizations.OrgGroups.OrgGroup
  alias Skoller.Organizations.OrgGroupOwners.OrgGroupOwner
  alias Skoller.Organizations.Watchlists.OrgGroupOwnerWatchlistItems

  schema "org_group_owners" do
    belongs_to :org_group, OrgGroup
    belongs_to :user, User

    has_many :watchlist_items, OrgGroupOwnerWatchlistItems
  end

  @all_fields ~w[org_group_id user_id]a

  def insert_changeset(params), do: %OrgGroupOwner{} |> update_changeset(params)

  def update_changeset(%OrgGroupOwner{} = owner, params) do
    owner
    |> cast(params, @all_fields)
    |> validate_required(@all_fields)
  end
end
