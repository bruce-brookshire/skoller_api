defmodule SkollerWeb.Api.V1.SkollerJobs.CareerActivityController do
  use SkollerWeb, :controller

  alias Skoller.SkollerJobs.CareerActivity
  alias Skoller.SkollerJobs.CareerActivities
  alias Skoller.SkollerJobs.JobProfiles.JobProfile
  alias SKollerWeb.SkollerJobs.CareerActivityView

  import SkollerWeb.Plugs.Auth

  @student_role 100

  # Require access to be by a student
  plug :verify_role, %{role: @student_role}
  # Only require ownership when profile is not being created
  plug :verify_owner, :jobs_profile

  def create(%{assigns: %{profile: profile}} = conn, %{"user_id" => user_id} = params) do
    case CareerActivities.insert(profile) do
      %CareerActivity{} = activity ->
        conn
        |> put_view(CareerActivityView)
        |> render("show.json", activity: activity)

      _ ->
        conn |> send_resp(404, "unable to insert")
    end
  end
end
