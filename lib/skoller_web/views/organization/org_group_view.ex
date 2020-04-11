defmodule SkollerWeb.Organization.OrgGroupView do
  use SkollerWeb, :view

  alias SkollerWeb.Organization.OrgGroupView

  def render("index.json", %{org_groups: groups}), do: render_many(groups, OrgGroupView, "show.json")

  def render("show.json", %{org_group: group}), do: 
    group |> Map.take([:name, :organization_id])
end