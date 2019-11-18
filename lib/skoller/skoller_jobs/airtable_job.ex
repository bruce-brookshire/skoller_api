defmodule Skoller.SkollerJobs.AirtableJobType do
  use Ecto.Schema

  schema "airtable_job_types" do
    field :name, :string
  end
end

defmodule Skoller.SkollerJobs.AirtableJobs.AirtableJob do
  use Ecto.Schema

  alias Skoller.SkollerJobs.AirtableJobType
  alias Skoller.SkollerJobs.JobProfiles.JobProfile
  alias Skoller.SkollerJobs.AirtableJobs.AirtableJob

  import Ecto.Changeset

  schema "airtable_jobs" do
    field :is_running, :boolean, default: false

    field :airtable_object_id, :string
    field :airtable_job_type_id, :id
    field :job_profile_id, :id

    belongs_to :airtable_job_type, AirtableJobType, define_field: false
    belongs_to :job_profile, JobProfile, define_field: false
  end

  @req_fields [:airtable_job_type_id]
  @upd_fields [:is_running]
  @all_fields @req_fields ++ [:is_running, :airtable_object_id, :job_profile_id]

  def changeset_insert(%{} = params) do
    %AirtableJob{}
    |> cast(params, @all_fields)
    |> validate_required(@req_fields)
    |> unique_constraint(:airtable_job_type_id)
    |> unique_constraint(:job_profile_id)
  end

  def changeset_update(%AirtableJob{} = job, %{} = params), do: cast(job, params, @upd_fields)
end
