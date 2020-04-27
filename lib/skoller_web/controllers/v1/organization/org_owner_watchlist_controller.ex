defmodule SkollerWeb.Api.V1.Organization.OrgOwnerWatchlistController do
  alias Skoller.Organizations.OrgOwnerWatchlistItems
  alias SkollerWeb.Organization.OrgOwnerWatchlistView

  use ExMvc.Controller, adapter: OrgOwnerWatchlistItems, view: OrgOwnerWatchlistView
end
