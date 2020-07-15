defmodule SkollerWeb.Api.V1.Organization.OrgMemberController do
  alias Skoller.Organizations.OrgMembers
  alias SkollerWeb.Organization.OrgMemberView
  
  use ExMvc.Controller, adapter: OrgMembers, view: OrgMemberView
end