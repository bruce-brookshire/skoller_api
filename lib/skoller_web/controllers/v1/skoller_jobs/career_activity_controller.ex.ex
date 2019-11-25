defmodule SkollerWeb.Api.V1.SkollerJobs.CareerActivityController do
  use SkollerWeb, :controller

  alias Skoller.SkollerJobs.CareerActivity
  alias Skoller.SkollerJobs.CareerActivities
  alias SkollerWeb.SkollerJobs.CareerActivityView

  import SkollerWeb.Plugs.Auth

  @student_role 100

  # Require access to be by a student
  plug :verify_role, %{role: @student_role}
  # Require ownership to work with activities
  plug :verify_owner, :jobs_profile
  # Require activity to be a member of the profile its attached to
  plug :verify_member, :job_activity when action in [:show, :update, :delete]

  def create(%{assigns: %{profile: profile}} = conn, params) do
    result =
      params
      |> Map.put("job_profile_id", profile.id)
      |> CareerActivities.insert()

    case result do
      {:ok, %CareerActivity{} = activity} ->
        conn
        |> put_view(CareerActivityView)
        |> render("show.json", activity: activity)

      _ ->
        send_resp(conn, 422, "unable to insert")
    end
  end

  def show(conn, %{"activity_id" => activity_id}) do
    case CareerActivities.get_by_id(activity_id) do
      %CareerActivity{} = activity ->
        conn
        |> put_view(CareerActivityView)
        |> render("show.json", activity: activity)

      _ ->
        send_resp(conn, 404, "Activity not found")
    end
  end

  def index(%{assigns: %{profile: profile}} = conn, %{"type_id" => type_id}) do
    case CareerActivities.get_by_profile_id_and_type_id(profile.id, String.to_integer(type_id)) do
      activities when is_list(activities) ->
        conn
        |> put_view(CareerActivityView)
        |> render("index.json", activities: activities)

      _ ->
        send_resp(conn, 404, "Something went wrong")
    end
  end

  def index(%{assigns: %{profile: profile}} = conn, _params) do
    case CareerActivities.get_by_profile_id(profile.id) do
      activities when is_list(activities) ->
        conn
        |> put_view(CareerActivityView)
        |> render("index.json", activities: activities)

      _ ->
        send_resp(conn, 404, "Something went wrong")
    end
  end

  def update(conn, %{"activity_id" => activity_id} = params) do
    case CareerActivities.get_by_id(activity_id) do
      %CareerActivity{} = activity ->
        {:ok, updated_activity} =
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
