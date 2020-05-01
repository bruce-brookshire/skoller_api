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

  def changeset(%__MODULE__{} = struct, params) do
    super(struct, params)
    |> unique_constraint(:user_id, name: :org_owners_user_id_organization_id_index)
  end
end
