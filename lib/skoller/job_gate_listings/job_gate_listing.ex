defmodule Skoller.JobGateListings.JobGateListing do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.JobGateListings.JobGateListing
  alias Skoller.JobGateListings.JobGateClassification
  alias Skoller.JobGateListings.JobGateClassificationJoiner

  @primary_key {:sender_reference, :string, autogenerate: false}
  schema "job_gate_listings" do
    ## Job details

    # Company offering job
    field :job_source, :string
    # What are you getting hired to do
    field :position, :string
    # Min salary
    field :salary_minimum, :string
    # Max salary
    field :salary_maximum, :string
    # What do they get paid in
    field :salary_currency, :string
    # What time period is the salary based over? salary / (salary_period, i.e. "year") <- hereg 
    field :salary_period, :string
    # Bonuses, etc
    field :salary_additional, :string
    # State
    field :region, :string
    # City
    field :locality, :string
    # USA (i think always)
    field :country, :string
    # Full time, part time, etc
    field :work_hours, :string
    # Contract, Temp, permanent, etc.
    field :employment_type, :string
    # No clue what format this will be
    field :start_date, :string
    # HTML description of the job
    field :description_html, :string

    ## Resources

    # URL of company offering job
    field :job_source_url, :string
    # Application URL. This will be created such that it autofills the users information
    field :application_url, :string
    # JobG8 posting page
    field :description_url, :string
    # Logo for the ADVERTISER (not necessarily the company hiring)
    field :logo_url, :string

    ## Private details

    # What kind of action for this job gets us paid? (APPLICATION, ATS, or TRAFFIC)
    field :job_type, :string
    # How much do we get paid for this link? (this will likely not be on route)
    field :sell_price, :string
    # How we get paid (Per application ("CPA") or per click ("CPC"))
    field :revenue_type, :string

    # Name of the advertiser
    field :advertiser_name, :string
    # Type of the advertiser
    field :advertiser_type, :string

    many_to_many :classifications, JobGateClassification,
      join_through: JobGateClassificationJoiner,
      join_keys: [job_gate_sender_reference: :sender_reference, job_gate_classification_id: :id]

    timestamps()
  end

  @req_fields [
    :sender_reference,
    :position,
    :salary_currency,
    :salary_period,
    :region,
    :locality,
    :country,
    :work_hours,
    :employment_type,
    :description_html,
    :application_url,
    :description_url,
    :job_type,
    :sell_price,
    :revenue_type,
    :advertiser_name,
    :advertiser_type
  ]

  @opt_fields [
    :job_source,
    :salary_minimum,
    :salary_maximum,
    :salary_additional,
    :start_date,
    :job_source_url,
    :logo_url
  ]

  @all_fields @req_fields ++ @opt_fields

  def insert_changeset(%{} = attrs),
    do:
      base_changeset(%JobGateListing{}, attrs)
      |> unique_constraint(:sender_reference, name: :job_gate_listings_pkey)

  def update_changeset(%JobGateListing{} = listing, %{} = attrs),
    do: base_changeset(listing, attrs)

  defp base_changeset(listing, attrs),
    do:
      listing
      |> cast(attrs, @all_fields)
      |> validate_required(@req_fields)
      |> validate_length(:description_html,
        max: 10_000,
        message: "Description longer than 10,000 characters"
      )
end
