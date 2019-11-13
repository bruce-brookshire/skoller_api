defmodule Skoller.SkollerJobs.CareerActivity do
  use Ecto.Schema

  alias Skoller.SkollerJobs.CareerActivity
  alias Skoller.SkollerJobs.CareerActivityType
  alias Skoller.SkollerJobs.JobProfiles.JobProfile

  import Ecto.Changeset

  schema "career_activities" do
    field :name, :string
    field :description, :string
    field :organization_name, :string
    field :start_date, :date
    field :end_date, :date
    field :job_profile_id, :id
    field :activity_type_id, :id

    belongs_to :job_profile, JobProfile, define_field: false
    belongs_to :career_activity_type, CareerActivityType, define_field: false

    timestamps()
  end

  @req_fields [:name, :organization_name, :start_date, :job_profile_id, :activity_type_id]
  @opt_fields [:end_date, :description]
  @all_fields @req_fields ++ @opt_fields

  def insert_changeset(params), do: update_changeset(%CareerActivity{}, params)

  def update_changeset(%CareerActivity{} = changeset, params) do
    changeset
    |> cast(params, @all_fields)
    |> validate_required(@req_fields)
  end
end
