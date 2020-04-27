defmodule SkollerWeb.Api.V1.Organization.OrgGroupController do
  alias Skoller.Organizations.OrgGroups
  alias SkollerWeb.Organization.OrgGroupView

  import SkollerWeb.Plugs.InsightsAuth

  use ExMvc.Controller,
    adapter: OrgGroups,
    view: OrgGroupView,
    plugs: plug(:verify_owner, :org_group)
end
