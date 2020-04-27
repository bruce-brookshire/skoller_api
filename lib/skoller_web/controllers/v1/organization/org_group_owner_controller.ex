defmodule SkollerWeb.Api.V1.Organization.OrgGroupOwnerController do
  alias Skoller.Organizations.OrgGroupOwners
  alias SkollerWeb.Organization.OrgOwnerView

  use ExMvc.Controller, adapter: OrgGroupOwners, view: OrgOwnerView
end
