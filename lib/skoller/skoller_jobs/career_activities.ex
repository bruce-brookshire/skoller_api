defmodule Skoller.SkollerJobs.CareerActivities do
  alias Skoller.Repo
  alias Skoller.SkollerJobs.CareerActivity

  def insert(params) do
    params
    |> CareerActivity.insert_changeset()
    |> Repo.insert()
  end

  def update(%CareerActivity{} = activity, params) do
    activity
    |> CareerActivity.update_changeset(params)
    |> Repo.update()
  end

  def get_by_id(id) when is_binary(id), do: get_by_id(String.to_integer(id))

  def get_by_id(id) when is_integer(id), do: Repo.get(CareerActivity, id)

  def get_by_profile_id(profile_id) when is_binary(profile_id),
    do: get_by_id(String.to_integer(profile_id))

  def get_by_profile_id(profile_id) when is_integer(profile_id),
    do: Repo.get_by(CareerActivity, job_profile_id: profile_id)
end
