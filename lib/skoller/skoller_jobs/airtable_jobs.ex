defmodule Skoller.SkollerJobs.AirtableJobs do
  alias Skoller.Repo

  alias Skoller.SkollerJobs.AirtableJobType
  alias Skoller.SkollerJobs.JobProfiles.JobProfile
  alias Skoller.SkollerJobs.AirtableJobs.AirtableJob

  import Ecto.Query

  @create_type_id 100
  @update_type_id 200
  @delete_type_id 300

  def on_profile_create(%JobProfile{id: id}) do
    %{
      job_profile_id: id,
      airtable_job_type_id: @create_type_id
    }
    |> AirtableJob.changeset_insert()
    |> Repo.insert()
  end

  def on_profile_update(%JobProfile{id: id, airtable_object_id: airtable_object_id}) do
    %{
      job_profile_id: id,
      airtable_object_id: airtable_object_id,
      airtable_job_type_id: @update_type_id
    }
    |> AirtableJob.changeset_insert()
    |> Repo.insert()
  end

  def on_profile_delete(%JobProfile{airtable_object_id: airtable_object_id}) do
    %{
      airtable_object_id: airtable_object_id,
      airtable_job_type_id: @delete_type_id
    }
    |> AirtableJob.changeset_insert()
    |> Repo.insert()
  end

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

  def start_job!(%AirtableJob{is_running: false} = job) do
    job
    |> AirtableJob.changeset_update(%{is_running: true})
    |> Repo.update!()

    job
  end

  def complete_job!(%AirtableJob{} = job), do: Repo.delete!(job)
end
