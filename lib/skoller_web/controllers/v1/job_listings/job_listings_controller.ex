defmodule SkollerWeb.Api.V1.SkollerJobs.JobListingsController do
  use SkollerWeb, :controller

  alias Skoller.JobGateListings, as: Listings
  alias SkollerWeb.SkollerJobs.JobListingView

  def show(conn, %{"sender_reference" => sender_ref}) do
    with ref when is_binary(ref) <- sender_ref,
         job when not is_nil(job) <- Listings.get(ref) do
      put_view(conn, JobListingView)
      |> render("show.json", listing: job)
    else
      _ -> send_resp(conn, 404, "not found")
    end
  end

  def show(conn, _params), do: send_resp(conn, 422, "sender_reference not found")

  def index(conn, params) do
    offset = params["offset"] || 20

    listings = Listings.get_listings(with_offset: offset)

    conn
    |> put_view(JobListingView)
    |> render("index.json", listings: listings)
  end
end
