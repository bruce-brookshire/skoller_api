defmodule Skoller.SkollerJobs.JobProfiles do
  alias Skoller.Repo
  alias Skoller.SkollerJobs.JobProfiles.JobProfile
  alias Skoller.Users.User
  alias Ecto.Changeset

  @doc """
  Creates a job profile
  # Returns `{:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}`
  """
  def insert(params) do
    params
    |> JobProfile.insert_changeset()
    |> Repo.insert()
  end

  @doc """
  Get job profile by its id
  # Returns `Ecto.Schema.t() | nil`
  """
  def get_by_id(job_profile_id) when is_integer(job_profile_id),
    do: Repo.get(JobProfile, job_profile_id)

  def get_by_id(job_profile_id) when is_binary(job_profile_id),
    do: job_profile_id |> String.to_integer() |> get_by_id()

  @doc """
  Get job profile by its user's id
  # Returns `Ecto.Schema.t() | nil`
  """
  def get_by_user(%User{id: user_id}), do: Repo.get_by(JobProfile, user_id: user_id)

  @doc """
  Update job profile
  # Returns `{:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}`
  """
  def update(nil, _params), do: nil

  def update(%JobProfile{} = profile, params) do
    profile
    |> JobProfile.update_changeset(params)
    |> Repo.update()
  end

  def delete(%JobProfile{} = profile) do
    profile
    |> Repo.delete()
  end
end
