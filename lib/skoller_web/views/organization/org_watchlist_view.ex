defmodule SkollerWeb.Organization.OrgOwnerWatchlistView do
  alias Skoller.Organizations.OrgOwnerWatchlistItems.OrgOwnerWatchlistItem
  
  use ExMvc.View, model: OrgOwnerWatchlistItem
end

defmodule SkollerWeb.Organization.OrgGroupOwnerWatchlistView do
  alias Skoller.Organizations.OrgGroupOwnerWatchlistItems.OrgGroupOwnerWatchlistItem
  
  use ExMvc.View, model: OrgGroupOwnerWatchlistItem
end
