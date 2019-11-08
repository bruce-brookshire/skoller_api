defmodule Skoller.SkollerJobs.JobCandidateActivity do
  use Ecto.Schema

  alias Skoller.SkollerJobs.JobProfile
  alias Skoller.SkollerJobs.JobCandidateActivityType

  schema "job_candidate_activities" do
    field :name, :string
    field :description, :string
    field :organization_name, :string
    field :start_date, :date
    field :end_date, :date
    field :job_profile_id, :id
    field :job_candidate_activity_type_id, :id

    belongs_to :job_profile, JobProfile, define_field: false
    belongs_to :job_candidate_activity_type, JobCandidateActivityType, define_field: false
  end
end
