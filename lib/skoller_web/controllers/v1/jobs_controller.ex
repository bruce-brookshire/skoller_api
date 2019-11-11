defmodule SkollerWeb.Api.V1.JobsController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias SkollerWeb.JobsView
  alias Skoller.SkollerJobs.JobProfiles
  alias Skoller.SkollerJobs.JobProfiles.JobProfile

  import SkollerWeb.Plugs.Auth

  @student_role 100

  plug :verify_role, %{role: @student_role}

  def create(conn, params) do
    params
    |> Map.put("user_id", conn.assigns[:user].id)
    |> JobProfiles.insert()
    |> construct_response(conn)
  end

  def show(conn, %{"id" => id}) do
    JobProfiles.get_by_id(id)
    |> construct_response(conn)
  end

  def update(conn, %{"id" => id} = params) do
    id
    |> JobProfiles.get_by_id()
    |> JobProfile.update_changeset(params)
    |> construct_response(conn)

    # case JobProfiles.get_by_id(id) do
    #   nil -> 
    #     construct_response(nil, conn)

    #   profile ->
    #     plug :verify_member,

    # end
    # |> JobProfiles.update(params)
    # |> construct_response(conn)
  end

  def delete(conn, %{"id" => id}) do
    result =
      JobProfiles.get_by_id(id)
      |> JobProfiles.delete()

    case result do
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

  defp construct_response(%JobProfile{} = profile, conn),
    do: construct_response({:ok, profile}, conn)

  defp construct_response({:ok, %JobProfile{} = profile}, conn) do
    profile =
      profile
      |> Repo.preload([:job_profile_status, :ethnicity_type, :degree_type, :job_activities])

    conn
    |> put_view(JobsView)
    |> render("show.json", profile: profile)
  end

  defp construct_response({:error, %{errors: errors}}, conn),
    do:
      put_status(conn, 422)
      |> json(%{errors: changeset_error_reducer(errors)})

  defp construct_response(_error, conn),
    do: send_resp(conn, 422, "Issue getting, changing, or inserting object")

  defp changeset_error_reducer(errors),
    do:
      Enum.map(errors, fn {k, v} -> {to_string(k), elem(v, 0)} end)
      |> Map.new()
end
