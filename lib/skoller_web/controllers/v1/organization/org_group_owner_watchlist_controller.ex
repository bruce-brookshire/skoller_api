defmodule SkollerWeb.Api.V1.Organization.OrgGroupOwnerWatchlistController do
  alias Skoller.Organizations.OrgGroupOwnerWatchlistItems
  alias SkollerWeb.Organization.OrgGroupOwnerWatchlistView

  use ExMvc.Controller, adapter: OrgGroupOwnerWatchlistItems, view: OrgGroupOwnerWatchlistView
end
