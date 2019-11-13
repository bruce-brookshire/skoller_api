defmodule Skoller.Repo.Migrations.SkollerJobs do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.SkollerJobs.DegreeType
  alias Skoller.SkollerJobs.EthnicityType
  alias Skoller.SkollerJobs.JobProfileStatus
  alias Skoller.SkollerJobs.CareerActivityType

  def up do
    # Types and Statuses
    create table(:ethnicity_types) do
      add(:name, :string)
    end

    create table(:degree_types) do
      add(:name, :string)
    end

    create table(:job_profile_statuses) do
      add(:name, :string)
    end

    create table(:career_activity_types) do
      add(:name, :string)
    end

    flush()

    # Insert types

    [
      %JobProfileStatus{id: 100, name: "Active"},
      %JobProfileStatus{id: 200, name: "Sleeping"},
      %JobProfileStatus{id: 300, name: "Disabled"}
    ]
    |> Enum.each(&Repo.insert/1)

    [
      %DegreeType{id: 100, name: "Bachelors"},
      %DegreeType{id: 200, name: "Masters"},
      %DegreeType{id: 300, name: "Ph. D."},
      %DegreeType{id: 400, name: "MBA"},
      %DegreeType{id: 500, name: "JD"}
    ]
    |> Enum.each(&Repo.insert/1)

    [
      %EthnicityType{id: 100, name: "White"},
      %EthnicityType{id: 200, name: "Black or African American"},
      %EthnicityType{id: 300, name: "American Indian or Alaska Native"},
      %EthnicityType{id: 400, name: "Asian"},
      %EthnicityType{id: 500, name: "Native Hawaiian or other Pacific Islander"},
      %EthnicityType{id: 600, name: "Hispanic or Latino"},
      %EthnicityType{id: 700, name: "Other"},
      %EthnicityType{id: 800, name: "Not specified"}
    ]
    |> Enum.each(&Repo.insert/1)

    [
      %CareerActivityType{id: 100, name: "Volunteer"},
      %CareerActivityType{id: 200, name: "Clubs"},
      %CareerActivityType{id: 300, name: "Achievements"},
      %CareerActivityType{id: 400, name: "Experience"}
    ]
    |> Enum.each(&Repo.insert/1)

    create table(:job_profiles) do
      # Foreign keys
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:ethnicity_type_id, references(:ethnicity_types, on_delete: :nilify_all))
      add(:job_profile_status_id, references(:job_profile_statuses, on_delete: :nilify_all))
      add(:degree_type_id, references(:degree_types, on_delete: :nilify_all))

      # Basic details
      add(:alt_email, :string)
      add(:state_code, :string, length: 2)
      add(:region, :string)
      add(:wakeup_date, :naive_datetime)
      add(:short_sell, :string, length: 300)
      add(:skills, :string, length: 200)

      # Work eligibility
      add(:work_auth, :boolean)
      add(:sponsorship_required, :boolean)
      add(:played_sports, :boolean)

      # Docs
      add(:transcript_url, :string)
      add(:resume_url, :string)

      # Data maps
      add(:social_links, {:map, :string})
      add(:update_at_timestamps, {:map, :string})
      add(:personality, {:map, :string})
      add(:company_values, {:map, :integer})

      # Numbers
      add(:gpa, :float)
      add(:act_score, :integer)
      add(:sat_score, :integer)
      add(:startup_interest, :integer)

      # Equal opportunity booleans
      add(:gender, :string, length: 9)
      add(:veteran, :boolean)
      add(:disability, :boolean)
      add(:first_gen_college, :boolean)
      add(:fin_aid, :boolean)
      add(:pell_grant, :boolean)

      timestamps()
    end

    create table(:career_activities) do
      add(:name, :string)
      add(:description, :string, length: 750)
      add(:organization_name, :string)
      add(:start_date, :date)
      add(:end_date, :date)
      add(:job_profile_id, references(:job_profiles, on_delete: :delete_all))

      add(
        :career_activity_type_id,
        references(:career_activity_types, on_delete: :delete_all)
      )

      timestamps()
    end

    flush()

    create(unique_index(:job_profiles, [:user_id]))
  end

  def down do
    # TODO take care of this
    drop(table(:job_candidate_activities))
    drop(table(:job_candidate_activity_types))
    # drop(table(:career_activities))
    # drop(table(:career_activity_types))
    drop(table(:job_profiles))
    drop(table(:ethnicity_types))
    drop(table(:job_profile_statuses))
    drop(table(:degree_types))
  end
end
