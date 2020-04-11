defmodule Skoller.Organizations.OrgOwners do
  import Ecto.Query

  alias Skoller.Organizations
  alias Organizations.Organization
  alias Organizations.OrgOwners.OrgOwner
  alias Organizations.OrgOwners
  alias Skoller.Users.User
  alias Skoller.Repo

  def get_by_id(id), do: Repo.get(OrgOwner, id)

  def index_by_user(%User{id: user_id}), do: index_by_user(user_id)

  def index_by_user(user_id) do
    OrgOwner
    |> where(user_id: ^user_id)
    |> Repo.all()
  end

  def index_by_org(%Organization{id: org_id}), do: index_by_org(org_id)

  def index_by_org(org_id) do
    OrgOwner
    |> where(organization_id: ^org_id)
    |> Repo.all()
  end

  def create(params) do
    params
    |> OrgOwner.insert_changeset()
    |> Repo.insert()
  end

  def update(owner_id, params) when is_integer(owner_id),
    do: owner_id |> get_by_id() |> OrgOwners.update(params)

  def update(%OrgOwner{} = owner, params) do
    owner
    |> OrgOwner.update_changeset(params)
    |> Repo.update()
  end
end
