defmodule SkollerWeb.Api.V1.Organization.OrgOwnerController do
  alias Skoller.Organizations.OrgOwners
  alias SkollerWeb.Organization.OrgOwnerView

  import SkollerWeb.Plugs.InsightsAuth

  use ExMvc.Controller,
    adapter: OrgOwners,
    view: OrgOwnerView,
    plugs: plug :verify_owner, :organization when action == :create
end
