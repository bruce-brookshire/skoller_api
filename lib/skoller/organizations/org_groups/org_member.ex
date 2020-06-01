defmodule Skoller.Organizations.OrgMembers.OrgMember do
  use Ecto.Schema
  
  alias Skoller.Users.User
  alias Skoller.Organizations.Organization

  schema "org_members" do
    belongs_to :user, User
    belongs_to :organization, Organization

    timestamps()
  end

  use ExMvc.ModelChangeset, req_fields: ~w[user_id organization_id]a
end