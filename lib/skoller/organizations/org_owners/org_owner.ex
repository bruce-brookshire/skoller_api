defmodule Skoller.Organizations.OrgOwners.OrgOwner do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Users.User
  alias Skoller.Organizations
  alias Organizations.Organization
  alias Organizations.OrgOwners.OrgOwner

  schema "org_owners" do
    belongs_to :organization, Organization
    belongs_to :user, User
  end

  @all_fields ~w[organization_id user_id]a

  def insert_changeset(params) do
    %OrgOwner{}
    |> cast(params, @all_fields)
    |> validate_required(params, @all_fields)
  end

  def update_changeset(%OrgOwner{} = struct, params) do
    struct
    |> cast(params, @all_fields)
    |> validate_required(params, @all_fields)
  end
end