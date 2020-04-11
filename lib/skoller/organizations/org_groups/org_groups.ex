defmodule Skoller.Organizations.OrgGroups do
  alias Skoller.Repo
  alias Skoller.Organizations.OrgGroups.OrgGroup

  def get_by_user_id(user_id), do: Repo.get(OrgGroup, user_id)

  def update(org_group_id, params), do: org_group_id |> get_by_user_id() |> update(params)

  def update(%OrgGroup{} = org_group, params),
    do: org_group |> OrgGroup.update_changeset(params) |> Repo.update()

  def create(params), do: params |> OrgGroup.insert_changeset() |> Repo.insert()
end
