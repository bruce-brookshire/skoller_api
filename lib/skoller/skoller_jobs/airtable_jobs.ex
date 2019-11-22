defmodule Skoller.SkollerJobs.AirtableJobs do
  alias Skoller.Repo

  alias Skoller.SkollerJobs.JobProfiles
  alias Skoller.SkollerJobs.JobProfiles.JobProfile
  alias Skoller.SkollerJobs.AirtableJobs.AirtableJob

  import Ecto.Query

  @create_type_id 100
  @update_type_id 200
  @delete_type_id 300

  @doc """
  When a profile is created, this should be called in order to 
  sync this profile to the airtable board

    - no need for id driven function since this function cannot 
      be a side-effect of modifying a user/student route)
  """
  def on_profile_create(%JobProfile{id: profile_id}),
    do: create_sync_job(profile_id, nil, @create_type_id)

  @doc """
  Profile updated
  """
  def on_profile_update(%JobProfile{id: profile_id, airtable_object_id: airtable_object_id}),
    do: create_sync_job(profile_id, airtable_object_id, @update_type_id)

  def on_profile_update(nil), do: nil

  def on_profile_update(profile_id) when is_integer(profile_id) do
    create_sync_job(profile_id, nil, @update_type_id)
  end

  @doc """
  Profile deleted
  """
  def on_profile_delete(%JobProfile{airtable_object_id: airtable_object_id}),
    do: create_sync_job(nil, airtable_object_id, @delete_type_id)

  def on_profile_delete(nil), do: nil

  def on_profile_delete(profile_id) when is_integer(profile_id) do
    %JobProfile{airtable_object_id: airtable_object_id} = JobProfiles.get_by_id(profile_id)
    create_sync_job(nil, airtable_object_id, @delete_type_id)
  end

  # Helper function to queue the job
  defp create_sync_job(profile_id, airtable_object_id, type_id) do
    %{
      job_profile_id: profile_id,
      airtable_object_id: airtable_object_id,
      airtable_job_type_id: type_id
    }
    |> AirtableJob.changeset_insert()
    |> Repo.insert()
  end

  @doc """
  Fetch the count specified of airtable_jobs of the type specified,
  where the job is not already running
  """
  def get_outstanding_jobs(type_id, count)
      when type_id in [@create_type_id, @update_type_id, @delete_type_id] do
    from(j in AirtableJob)
    |> where([j], not j.is_running and j.airtable_job_type_id == ^type_id)
    |> order_by([j], asc: j.inserted_at)
    |> limit(^count)
    |> preload([j],
      job_profile: [
        user: [
          student: [:primary_school, :fields_of_study]
        ],
        degree_type: [],
        ethnicity_type: []
      ]
    )
    |> Repo.all()
  end

  @doc """
  Sets the job to running, so that it cannot be run by another job
  """
  def start_job!(%AirtableJob{is_running: false} = job) do
    job
    |> AirtableJob.changeset_update(%{is_running: true})
    |> Repo.update!()
    
    job
  end
  
  @doc """
  Completes the job by removing it from the `"airtable_jobs"` table
  """
  def complete_job!(%AirtableJob{} = job), do: Repo.delete!(job)
end
