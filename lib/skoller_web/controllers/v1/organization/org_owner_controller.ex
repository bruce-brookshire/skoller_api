defmodule SkollerWeb.Api.V1.Organization.OrgOwnerController do
  alias Skoller.Organizations.OrgOwners
  alias SkollerWeb.Organization.OrgOwnerView

  use SkollerWeb.Controller, adapter: OrgOwners, view: OrgOwnerView
end
