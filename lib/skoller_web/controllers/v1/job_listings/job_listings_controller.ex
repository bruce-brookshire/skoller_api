defmodule SkollerWeb.Api.V1.SkollerJobs.JobListingsController do
  use SkollerWeb, :controller

  import SkollerWeb.Plugs.Auth

  alias Skoller.JobGateListings, as: Listings
  alias SkollerWeb.SkollerJobs.JobListingView

  plug :verify_owner, :with_jobs_profile

  def show(conn, %{"sender_reference" => sender_ref}) do
    with ref when is_binary(ref) <- sender_ref,
         job when not is_nil(job) <- Listings.get(ref) do
      put_view(conn, JobListingView)
      |> render("show.json", listing: job, user: conn.assigns.user)
    else
      _ -> send_resp(conn, 404, "not found")
    end
  end

  def show(conn, _params), do: send_resp(conn, 422, "sender_reference not found")

  def index(conn, params) do
    with offset <- params["offset"] || 20,
         listings <- Listings.get_listings(with_offset: offset),
         template_suffix <- if(params["min_view"] == "true", do: "-min", else: ""),
         template_name <- "index#{template_suffix}.json" do
      conn
      |> put_view(JobListingView)
      |> render(template_name, listings: listings, user: conn.assigns.user)
    else
      _ ->
        send_resp(conn, 422, "")
    end
  end
end
