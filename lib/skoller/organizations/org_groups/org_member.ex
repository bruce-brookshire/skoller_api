defmodule Skoller.Organizations.OrgMembers.OrgMember do
  use Ecto.Schema

  alias Skoller.Users.User
  alias Skoller.Organizations.{Organization, OrgGroupOwners.OrgGroupOwner}

  schema "org_members" do
    belongs_to :user, User
    belongs_to :organization, Organization

    has_many :org_group_owners, OrgGroupOwner
    has_many :org_groups, through: [:org_group_owners, :org_group]

    timestamps()
  end

  use ExMvc.ModelChangeset, req_fields: ~w[user_id organization_id]a
end
