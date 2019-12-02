defmodule Skoller.SkollerJobs.JobProfiles.JobProfile do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Users.User
  alias Skoller.SkollerJobs.DegreeType
  alias Skoller.SkollerJobs.EthnicityType
  alias Skoller.SkollerJobs.JobSearchType
  alias Skoller.SkollerJobs.CareerActivity
  alias Skoller.SkollerJobs.JobProfileStatus
  alias Skoller.SkollerJobs.JobProfiles.JobProfile

  schema "job_profiles" do
    field :user_id, :id

    field :job_profile_status_id, :id, default: 100
    field :wakeup_date, :naive_datetime
    field :graduation_date, :date

    field :alt_email, :string
    field :state_code, :string
    field :regions, :string
    field :short_sell, :string
    field :career_interests, :string
    field :skills, :string
    field :degree_type_id, :id
    field :job_search_type_id, :id

    # Work eligibility
    field :work_auth, :boolean
    field :sponsorship_required, :boolean
    field :played_sports, :boolean

    # Docs
    field :transcript_url, :string
    field :resume_url, :string

    # Data maps
    field :social_links, {:map, :string}
    field :update_at_timestamps, {:map, :string}
    field :personality, {:map, :string}
    field :company_values, {:map, :integer}

    # Numbers
    field :gpa, :float
    field :act_score, :integer
    field :sat_score, :integer
    field :startup_interest, :integer

    # Equal opportunity
    field :gender, :string
    field :ethnicity_type_id, :id
    field :veteran, :boolean
    field :disability, :boolean
    field :first_gen_college, :boolean
    field :fin_aid, :boolean
    field :pell_grant, :boolean

    field :airtable_object_id, :string

    # Relations
    belongs_to :user, User, define_field: false
    belongs_to :job_profile_status, JobProfileStatus, define_field: false
    belongs_to :ethnicity_type, EthnicityType, define_field: false
    belongs_to :degree_type, DegreeType, define_field: false
    belongs_to :job_search_type, JobSearchType, define_field: false

    has_many :volunteer_activities, CareerActivity, foreign_key: :job_profile_id, where: [career_activity_type_id: 100]
    has_many :club_activities, CareerActivity, foreign_key: :job_profile_id, where: [career_activity_type_id: 200]
    has_many :achievement_activities, CareerActivity, foreign_key: :job_profile_id, where: [career_activity_type_id: 300]
    has_many :experience_activities, CareerActivity, foreign_key: :job_profile_id, where: [career_activity_type_id: 400]

    timestamps()
  end

  @req_fields [:user_id, :degree_type_id]
  @opt_fields [
    :wakeup_date,
    :graduation_date,
    :alt_email,
    :state_code,
    :regions,
    :short_sell,
    :skills,
    :work_auth,
    :sponsorship_required,
    :job_profile_status_id,
    :career_interests,
    :played_sports,
    :transcript_url,
    :resume_url,
    :social_links,
    :update_at_timestamps,
    :personality,
    :company_values,
    :gpa,
    :act_score,
    :sat_score,
    :startup_interest,
    :gender,
    :ethnicity_type_id,
    :veteran,
    :disability,
    :first_gen_college,
    :fin_aid,
    :pell_grant,
    :job_search_type_id
  ]

  @airtable_fields [:airtable_object_id]

  @all_fields @req_fields ++ @opt_fields
  @all_airtable_fields @all_fields ++ @airtable_fields

  def insert_changeset(%{} = params) do
    %JobProfile{}
    |> cast(params, @all_fields)
    |> unique_constraint(:user_id)
    |> validate_required(@req_fields)
  end

  def update_changeset(%JobProfile{} = profile, %{} = params) do
    profile
    |> cast(params, @all_fields)
    |> unique_constraint(:user_id)
    |> validate_required(@req_fields)
  end

  def airtable_changeset(%JobProfile{} = profile, %{} = params) do
    profile
    |> cast(params, @all_airtable_fields)
    |> unique_constraint(:user_id)
    |> validate_required(@req_fields)
  end
end
