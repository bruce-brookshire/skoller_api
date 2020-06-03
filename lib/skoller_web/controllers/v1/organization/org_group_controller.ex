defmodule SkollerWeb.Api.V1.Organization.OrgGroupController do
  alias Skoller.Organizations.OrgGroups
  alias SkollerWeb.Organization.OrgGroupView

  import SkollerWeb.Plugs.InsightsAuth

  use ExMvc.Controller,
    adapter: OrgGroups,
    view: OrgGroupView

  plug(:verify_owner, :org_group when action in [:update, :show])
  plug(:verify_owner, :organization when action in [:create, :index, :delete])
end
