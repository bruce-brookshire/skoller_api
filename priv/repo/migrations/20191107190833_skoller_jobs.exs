defmodule Skoller.Repo.Migrations.SkollerJobs do
  use Ecto.Migration

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

    create table(:job_candidate_activity_types) do
      add(:name, :string)
    end

    create table(:job_profiles) do
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
      add(:act, :integer)
      add(:sat, :integer)
      add(:startup_interest, :integer)

      # Equal opportunity booleans
      add(:gender, :string, length: 9)
      add(:veteran, :boolean)
      add(:disability, :boolean)
      add(:first_gen_college, :boolean)
      add(:fin_aid, :boolean)
      add(:pell_grant, :boolean)

      # Foreign keys
      add(:ethnicity_type_id, references(:ethnicity_types, on_delete: :nilify_all))
      add(:job_profile_status_id, references(:job_profile_statuses, on_delete: :nilify_all))
      add(:degree_type_id, references(:degree_types, on_delete: :nilify_all))
    end

    create table(:job_candidate_activities) do
      add(:name, :string)
      add(:description, :string)
      add(:organization_name, :string)
      add(:start_date, :date)
      add(:end_date, :date)
      add(:job_profile_id, references(:job_profiles, on_delete: :delete_all))

      add(
        :job_candidate_activity_type_id,
        references(:job_candidate_activity_types, on_delete: :delete_all)
      )
    end
  end

  def down do
    drop(table(:degree_types))
    drop(table(:job_candidate_activities))
    drop(table(:job_candidate_activity_types))
    drop(table(:job_profiles))
    drop(table(:ethnicity_types))
    drop(table(:job_profile_statuses))
  end
end
