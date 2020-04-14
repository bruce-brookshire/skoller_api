defmodule SkollerWeb.Api.V1.Organization.OrgGroupOwnerController do
  alias Skoller.Organizations.OrgGroupOwners
  alias SkollerWeb.Organization.OrgOwnerView

  use SkollerWeb.Controller, adapter: OrgGroupOwners, view: OrgOwnerView
end
