defmodule SkollerWeb.Plugs.JobsAuth do
  import Plug.Conn

  alias Skoller.Repo
  alias Skoller.SkollerJobs.{JobProfiles, JobProfiles.JobProfile}

  def verify_owner(
        %{params: %{"profile_id" => id}, assigns: %{user: %{id: user_id}}} = conn,
        :jobs_profile
      ) do
    case JobProfiles.get_by_id_and_user_id(id, user_id) do
      %JobProfile{} = profile -> assign(conn, :profile, profile)
      _ -> conn |> unauth
    end
  end

  def verify_owner(
        %{params: %{"id" => id}, assigns: %{user: %{id: user_id}}} = conn,
        :jobs_profile
      ) do
    case JobProfiles.get_by_id_and_user_id(id, user_id) do
      %JobProfile{} = profile -> assign(conn, :profile, profile)
      _ -> conn |> unauth
    end
  end

  def verify_owner(conn, :jobs_profile), do: conn |> unauth

  def verify_owner(%{assigns: %{user: user}} = conn, :with_jobs_profile) do
    case Repo.preload(user, [:job_profile]) do
      %{job_profile: profile} = new_user when not is_nil(profile) ->
        conn |> assign(:user, new_user)

      _ ->
        unauth(conn)
    end
  end

  defp unauth(conn), do: conn |> send_resp(401, "Unauthorized") |> halt()
end
