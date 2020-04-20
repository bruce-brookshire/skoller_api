defmodule SkollerWeb.Api.V1.SkollerJobs.JobListingActionController do
  use SkollerWeb, :controller

  import SkollerWeb.Plugs.Auth

  alias Skoller.JobGateListings.Actions
  alias Skoller.JobGateListings, as: Listings

  plug :verify_owner, :with_jobs_profile

  @actions ["viewed_job", "clicked_application"]

  def create(
        %{assigns: %{user: %{id: user_id}}} = conn,
        %{"action" => action, "job_listing_sender_reference" => ref} = params
      )
      when action in @actions do
        IO.inspect params
    {status, message} =
      with(
        true <- Listings.exists?(ref),
        body <- Map.put(params, "user_id", user_id),
        {:ok, _} <- Actions.create(body)
      ) do
        {204, ""}
      else
        false -> {422, "Job does not exist"}
        {:error, _} -> {422, "Issue inserting"}
      end

    send_resp(conn, status, message)
  end

  def create(conn, params) do
    IO.inspect(params)
    send_resp(conn, 422, "Invalid Action or sender reference missing")
  end
end
