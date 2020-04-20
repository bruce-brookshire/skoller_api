defmodule SkollerWeb.Organization.OrgOwnerWatchlistView do
  alias Skoller.Organizations.OrgOwnerWatchlistItems.OrgOwnerWatchlistItem
  use SkollerWeb.View, model: OrgOwnerWatchlistItem, single_atom: :item, plural_atom: :items
end

defmodule SkollerWeb.Organization.OrgGroupOwnerWatchlistView do
  alias Skoller.Organizations.OrgGroupOwnerWatchlistItems.OrgGroupOwnerWatchlistItem
  use SkollerWeb.View, model: OrgGroupOwnerWatchlistItem, single_atom: :item, plural_atom: :items
end
