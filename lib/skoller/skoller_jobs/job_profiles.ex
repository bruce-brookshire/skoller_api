defmodule Skoller.SkollerJobs.JobProfiles do
  alias Skoller.Repo
  alias Skoller.SkollerJobs.JobProfiles.JobProfile
  alias Skoller.SkollerJobs.AirtableJobs
  alias Skoller.Users.User

  @doc """
  Creates a job profile
  # Returns `{:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}`
  """
  def insert(params) do
    result =
      params
      |> JobProfile.insert_changeset()
      |> Repo.insert()

    case result do
      {:ok, %JobProfile{} = profile} -> AirtableJobs.on_profile_create(profile)
      _ -> nil
    end

    result
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
  def get_by_user(_), do: nil

  @doc """
  Get job profile by its user's id
  # Returns `Ecto.Schema.t() | nil`
  """
  def get_by_id_and_user_id(profile_id, user_id),
    do: Repo.get_by(JobProfile, user_id: user_id, id: profile_id)

  @doc """
  Update job profile
  # Returns `{:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}`
  """
  def update(nil, _params), do: nil

  def update(%JobProfile{} = profile, params) do
    result =
      profile
      |> JobProfile.update_changeset(params)
      |> Repo.update()

    case result do
      {:ok, %JobProfile{} = profile} -> AirtableJobs.on_profile_update(profile)
      _ -> nil
    end

    result
  end

  def delete(%JobProfile{} = profile) do
    result = profile
    |> Repo.delete()

    case result do
      {:ok, %JobProfile{} = profile} -> 
        AirtableJobs.on_profile_delete(profile)
      _ -> nil
    end

    result
  end
end
