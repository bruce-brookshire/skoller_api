defmodule Skoller.Organizations.OrgGroups.OrgGroup do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Organizations.Organization
  alias Skoller.Organizations.OrgGroups.OrgGroup
  alias Skoller.Organizations.OrgGroupOwners.OrgGroupOwner

  schema "org_groups" do
    field :name, :string

    belongs_to :organization, Organization
    has_many :owners, OrgGroupOwner
  end

  @all_fields ~w[name organization_id]

  def insert_changeset(params) do
    %OrgGroup{}
    |> cast(params, @all_fields)
    |> validate_required(@all_fields)
  end

  def update_changeset(%OrgGroup{} = orgGroup, params) do
    orgGroup
    |> cast(params, @all_fields)
    |> validate_required(@all_fields)
  end
end
