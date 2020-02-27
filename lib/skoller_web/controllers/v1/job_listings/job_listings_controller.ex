defmodule SkollerWeb.Api.V1.SkollerJobs.JobListingsController do
  use SkollerWeb, :controller

  alias Skoller.JobGateListings
  alias SkollerWeb.SkollerJobs.JobListingView

  def index(conn, params) do
    offset = params["offset"] || 20

    listings = JobGateListings.get_listings(with_offset: offset)

    conn
    |> put_view(JobListingView)
    |> render("index.json", listings: listings)
  end
end