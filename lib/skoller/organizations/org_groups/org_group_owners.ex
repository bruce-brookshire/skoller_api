defmodule Skoller.Organizations.OrgGroupOwners do
  alias Skoller.Repo
  alias Skoller.Organizations.OrgGroupOwners.OrgGroupOwner

  def get_by_id(owner_id), do: Repo.get(OrgGroupOwner, owner_id)

  def update(owner_id, params) when is_integer(owner_id),
    do: owner_id |> get_by_id() |> update(params)

  def update(%OrgGroupOwner{} = owner, params),
    do: owner |> OrgGroupOwner.update_changeset(params) |> Repo.update()

  def create(params), do: params |> OrgGroupOwner.insert_changeset() |> Repo.insert()
end
