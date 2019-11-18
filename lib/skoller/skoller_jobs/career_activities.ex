defmodule Skoller.SkollerJobs.CareerActivities do
  alias Skoller.Repo
  alias Skoller.SkollerJobs.CareerActivity

  import Ecto.Query

  def get_by_id(id) when is_binary(id), do: get_by_id(String.to_integer(id))

  def get_by_id(id) when is_integer(id), do: Repo.get(CareerActivity, id)

  def get_by_profile_id(profile_id) when is_binary(profile_id),
    do: get_by_profile_id(String.to_integer(profile_id))

  def get_by_profile_id(profile_id) when is_integer(profile_id) do
    from(c in CareerActivity)
    |> where([c], c.job_profile_id == ^profile_id)
    |> Repo.all()
  end
  
  def get_by_profile_id_and_type_id(profile_id, type_id) when is_binary(profile_id) and is_binary(type_id),
    do: get_by_profile_id_and_type_id(String.to_integer(profile_id), String.to_integer(type_id))

  def get_by_profile_id_and_type_id(profile_id, type_id) when is_integer(profile_id) and is_integer(type_id)do
    from(c in CareerActivity)
    |> where([c], c.job_profile_id == ^profile_id and c.career_activity_type_id == ^type_id)
    |> Repo.all()
  end

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

  def delete!(%CareerActivity{} = activity), do: Repo.delete!(activity)
end
