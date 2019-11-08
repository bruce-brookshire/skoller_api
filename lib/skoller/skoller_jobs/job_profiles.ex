defmodule Skoller.SkollerJobs.JobProfiles do
  import Ecto.Query

  alias Skoller.Repo
  alias Skoller.SkollerJobs.JobProfile
  alias Skoller.Users.User

  def insert(params) do
    params
    |> JobProfile.insert_changeset()
    |> Repo.insert()
  end

  def get_by_id(job_profile_id) when is_integer(job_profile_id) do
    JobProfile
    |> Repo.get(job_profile_id)
  end

  def get_profile_by_user(%User{id: user_id}) do
    JobProfile
    |> Repo.get_by(user_id: user_id)
  end

  def update(%JobProfile{} = profile, params) do
    profile
    |> JobProfile.update_changeset(params)
    |> Repo.update()
  end
end
