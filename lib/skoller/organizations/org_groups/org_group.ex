defmodule Skoller.Organizations.OrgGroups.OrgGroup do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Organizations.Organization
  alias Skoller.Organizations.OrgGroupOwners.OrgGroupOwner

  schema "org_groups" do
    field :name, :string

    belongs_to :organization, Organization
    has_many :owners, OrgGroupOwner
  end

  use ExMvc.ModelChangeset, req_fields: ~w[name organization_id]a
end
