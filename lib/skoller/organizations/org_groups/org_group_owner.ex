defmodule Skoller.Organizations.OrgGroupOwners.OrgGroupOwner do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Users.User
  alias Skoller.Organizations.OrgGroups.OrgGroup

  schema "org_group_owners" do
    belongs_to :org_group, OrgGroup
    belongs_to :user, User
  end
end 