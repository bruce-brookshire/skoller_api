defmodule SkollerWeb.Organization.OrgOwnerView do
  use SkollerWeb, :view

  alias SkollerWeb.Organization.OrgOwnerView

  def render("index.json", %{org_owners: owners}),
    do: owners |> render_many(owners, OrgOwnerView, "show.json")

  def render("show.json", %{org_owner: owner}),
    do: %{
      id: owner.id,
      user_id: owner.user.id,
      email: owner.user.email,
      organization_id: owner.organization_id
    }
end
