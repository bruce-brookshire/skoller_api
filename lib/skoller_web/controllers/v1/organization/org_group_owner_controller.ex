defmodule SkollerWeb.Api.V1.Organization.OrgGroupOwnerController do
  alias Skoller.Organizations.OrgGroupOwners
  alias SkollerWeb.Organization.OrgOwnerView
  
  import SkollerWeb.Plugs.InsightsAuth
  
  use ExMvc.Controller, adapter: OrgGroupOwners, view: OrgOwnerView

  plug :verify_owner, :org_group when action in [:index, :show]
  plug :verify_owner, :organization when action in [:create, :update, :delete]
end
