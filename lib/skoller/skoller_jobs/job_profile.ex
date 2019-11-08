defmodule Skoller.SkollerJobs.JobProfile do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Users.User
  alias Skoller.SkollerJobs.JobProfileStatus
  alias Skoller.SkollerJobs.EthnicityType
  alias Skoller.SkollerJobs.JobProfile
  alias Skoller.SkollerJobs.DegreeType

  schema "job_profiles" do
    field :user_id, :id

    field :job_profile_status_id, :id
    field :wakeup_date, :naive_datetime

    field :alt_email, :string
    field :state_code, :string
    field :region, :string
    field :short_sell, :string
    field :skills, :string
    field :degree_type_id, :id

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
    field :act, :integer
    field :sat, :integer
    field :startup_interest, :integer

    # Equal opportunity
    field :gender, :string
    field :ethnicity_type_id, :id
    field :veteran, :boolean
    field :disability, :boolean
    field :first_gen_college, :boolean
    field :fin_aid, :boolean
    field :pell_grant, :boolean

    # Relations
    belongs_to :user, User, define_field: false
    belongs_to :job_profile_status, JobProfileStatus, define_field: false
    belongs_to :ethnicity_type, EthnicityType, define_field: false
    belongs_to :degree_type, DegreeType, define_field: false
  end

  @req_fields [:user_id, :job_profile_status_id, :degree_type_id]
  @opt_fields [
    :wakeup_date,
    :alt_email,
    :state_code,
    :region,
    :short_sell,
    :skills,
    :work_auth,
    :sponsorship_required,
    :played_sports,
    :transcript_url,
    :resume_url,
    :social_links,
    :update_at_timestamps,
    :personality,
    :company_values,
    :gpa,
    :act,
    :sat,
    :startup_interest,
    :gender,
    :ethnicity_type_id,
    :veteran,
    :disability,
    :first_gen_college,
    :fin_aid,
    :pell_grant
  ]

  @all_fields @req_fields ++ @opt_fields

  def insert_changeset(%{} = params) do
    %JobProfile{}
    |> cast(params, @all_fields)
    |> validate_required(@req_fields)
  end

  def update_changeset(%JobProfile{id: _id} = profile, %{} = params) do
    profile
    |> cast(params, @all_fields)
    |> validate_required(@req_fields)
  end
end
