defmodule SkollerWeb.Api.V1.Organization.OrgGroupController do
  alias Skoller.Organizations.OrgGroups
  alias SkollerWeb.Organization.OrgGroupView

  use SkollerWeb.Controller, adapter: OrgGroups, view: OrgGroupView
end
