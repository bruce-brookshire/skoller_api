defmodule SkollerWeb.Api.V1.JobsController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.SkollerJobs.JobProfiles
  alias Skoller.SkollerJobs.JobProfiles.JobProfile

  import SkollerWeb.Plugs.Auth

  @student_role 100

  plug :verify_role, %{role: @student_role}

  def create(conn, params) do
    case JobProfiles.insert(params) do
      {:ok, profile} ->
        profile

      val ->
        IO.inspect(val)
        nil
    end
    |> construct_response(conn)
  end

  def show(conn, %{"id" => id}) do
    case JobProfiles.get_by_id(id) do
      {:ok, profile} ->
        profile

      _ ->
        nil
    end
    |> construct_response(conn)
  end

  def update(conn, %{"id" => id} = params) do
    profile =
      id
      |> JobProfiles.get_by_id()
      |> JobProfile.update_changeset(params)

    case profile do
      {:ok, profile} ->
        profile

      {:error, changeset} ->
        changeset

      _ ->
        nil
    end
    |> construct_response(conn)
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
    profile =
      conn.assigns[:user]
      |> JobProfiles.get_by_user()

    case profile do
      {:ok, profile} ->
        profile

      _ ->
        nil
    end
    |> construct_response(conn)
  end

  defp construct_response(%JobProfile{} = profile, conn) do
    profile =
      profile
      |> Repo.preload([:job_profile_status, :ethnicity_type, :degree_type])

    conn
    |> put_view(JobsView)
    |> render("show.json", profile: profile)
  end

  defp construct_response(nil, conn), do: send_resp(conn, 404, "Profile not found")

  defp construct_response(_error, conn),
    do: send_resp(conn, 422, "Issue changing or inserting object")
end
