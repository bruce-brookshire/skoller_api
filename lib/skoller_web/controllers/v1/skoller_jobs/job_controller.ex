defmodule SkollerWeb.Api.V1.SkollerJobs.JobController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias SkollerWeb.SkollerJobs.JobView
  alias Skoller.SkollerJobs.JobProfiles
  alias Skoller.SkollerJobs.JobProfiles.JobProfile

  import SkollerWeb.Plugs.Auth

  @student_role 100

  # Require access to be by a student
  plug :verify_role, %{role: @student_role}
  # Only require ownership when profile is not being created
  plug :verify_owner, :jobs_profile when not (action in [:create, :get_by_user])

  def create(conn, params) do
    params
    |> Map.put("user_id", conn.assigns[:user].id)
    |> JobProfiles.insert()
    |> construct_response(conn)
  end

  def show(%{assigns: %{profile: profile}} = conn, _params) do
    profile
    |> construct_response(conn)
  end

  def update(%{assigns: %{profile: profile}} = conn, params) do
    profile
    |> JobProfiles.update(params)
    |> construct_response(conn)
  end

  def delete(%{assigns: %{profile: profile}} = conn, _params) do
    case JobProfiles.delete(profile) do
      {:ok, _profile} ->
        conn |> send_resp(204, "")

      {:error, _changeset} ->
        conn |> send_resp(422, "Failed to delete profile")
    end
  end

  def get_by_user(conn, _params) do
    conn.assigns[:user]
    |> JobProfiles.get_by_user()
    |> construct_response(conn)
  end

  defp construct_response(nil, conn), do: send_resp(conn, 404, "Profile not found")

  defp construct_response(%JobProfile{} = profile, conn) do
    profile =
      profile
      |> Repo.preload([:job_profile_status, :ethnicity_type, :degree_type, :career_activities])

    conn
    |> put_view(JobView)
    |> render("show.json", profile: profile)
  end

  defp construct_response({:ok, %JobProfile{} = profile}, conn),
    do: construct_response(profile, conn)

  defp construct_response({:error, %{errors: errors}}, conn),
    do:
      put_status(conn, 422)
      |> json(%{errors: changeset_error_reducer(errors)})

  defp construct_response(_error, conn),
    do: send_resp(conn, 422, "Issue getting, changing, or inserting object")

  defp changeset_error_reducer(errors),
    do:
      errors
      |> Enum.map(fn {k, v} -> {to_string(k), elem(v, 0)} end)
      |> Map.new()
end
