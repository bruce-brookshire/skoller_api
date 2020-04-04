defmodule Skoller.Organizations.OrgGroups.OrgGroup do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Organizations.Organization
  alias Skoller.Organizations.OrgGroups.OrgGroup

  schema "org_groups" do
    field :name, :string
    
    belongs_to :organization, Organization
  end
end