defmodule SkollerWeb.Organization.WatchlistView do
  use SkollerWeb, :view

  alias SkollerWeb.Organization.WatchlistView
  alias Skoller.Organizations.Watchlists.OrgOwnerWatchlistItems
  alias Skoller.Organizations.Watchlists.OrgGroupOwnerWatchlistItems

  def render("index.json", %{watchlists: watchlists}),
    do: render_many(watchlists, WatchlistView, "show.json")

  def render("show.json", %{watchlist: %OrgOwnerWatchlistItems{} = watchlist}), do: %{
    # student: watchlist.
    hello: :hi
  }

  def render("show.json", %{watchlist: %OrgGroupOwnerWatchlistItems{} = watchlist}), do: %{
    # student: watchlist.org_group_
  }
end
