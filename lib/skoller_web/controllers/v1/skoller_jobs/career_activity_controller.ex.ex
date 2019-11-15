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

  def create(%{assigns: %{profile: profile}} = conn, params) do
    case CareerActivities.insert(profile) do
      %CareerActivity{} = activity ->
        conn
        |> put_view(CareerActivityView)
        |> render("show.json", activity: activity)

      _ ->
        send_resp(conn, 422, "unable to insert")
    end
  end

  def update(conn, %{"activity_id" => activity_id} = params) do
    case CareerActivities.get_by_id(activity_id) do
      %CareerActivity{} = activity ->
        updated_activity =
          activity
          |> CareerActivities.update(params)

        put_view(conn, CareerActivityView) |> render("show.json", activity: updated_activity)

      _ ->
        send_resp(conn, 404, "Activity not found")
    end
  end

  def delete(conn, %{"activity_id" => activity_id}) do
    case CareerActivities.get_by_id(activity_id) do
      %CareerActivity{} = activity ->
        CareerActivities.delete!(activity)
        send_resp(conn, 204, "")

      _ ->
        send_resp(conn, 404, "Activity not found")
    end
  end
end
