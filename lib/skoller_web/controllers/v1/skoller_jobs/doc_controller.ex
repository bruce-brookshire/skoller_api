defmodule SkollerWeb.Api.V1.Jobs.DocController do
  use SkollerWeb, :controller

  alias Skoller.SkollerJobs.JobProfiles
  alias Skoller.SkollerJobs.JobProfiles.JobProfile

  import SkollerWeb.Plugs.Auth

  @student_role 100

  # Require access to be by a student
  plug :verify_role, %{role: @student_role}
  # Only require ownership when profile is not being created
  plug :verify_owner, :jobs_profile

  def upload(
        %{assigns: %{profile: %JobProfile{} = profile}} = conn,
        %{"file" => file, "type" => "resume"} = params
      ) do
    profile
    |> JobProfiles.update(%{resume_url: "new_url"})
  end

  def upload(
        %{assigns: %{profile: %JobProfile{} = profile}} = conn,
        %{"file" => file, "type" => "transcript"} = params
      ) do
    profile
    |> JobProfiles.update(%{transcript_url: "new_url"})
  end
end
