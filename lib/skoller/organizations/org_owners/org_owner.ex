defmodule Skoller.Organizations.OrgOwners.OrgOwner do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Users.User
  alias Skoller.Organizations.Organization

  schema "org_owners" do
    belongs_to :organization, Organization
    belongs_to :user, User
  end

  use ExMvc.ModelChangeset, req_fields: ~w[organization_id user_id]a
end
