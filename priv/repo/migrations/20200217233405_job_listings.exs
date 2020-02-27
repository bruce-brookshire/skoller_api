defmodule Skoller.Repo.Migrations.JobListings do
  use Ecto.Migration

  def up do

    # Helper join tables to associate JobG8 naming schemes to Skoller Naming Schemes
    create table(:job_gate_column_types) do
      add(:column_name, :string)
    end

    create table(:job_gate_naming_transforms) do
      add(:job_gate_column_type_id, references(:job_gate_column_types, on_delete: :delete_all))
      add(:job_gate_content_name, :string)
      add(:profile_content_associated_name, :string)
    end

    # JobG8 listing
    create table(:job_gate_listings, primary_key: false) do

      # JobG8 Identifier
      add(:sender_reference, :string, size: 30, null: false, primary_key: true, unique: true) # JobG8 ID
      
      # Job details
      add(:job_source, :string, size: 100) # Company offering job
      
      add(:position, :string, size: 70, null: false) # What are you getting hired to do
      
      add(:salary_minimum, :string, size: 20) # Min salary
      add(:salary_maximum, :string, size: 20) # Max salary
      add(:salary_currency, :string, size: 70, null: false) # What do they get paid in
      add(:salary_period, :string, size: 70, null: false) # What time period is the salary based over? salary / (salary_period, i.e. "year") <- here
      add(:salary_additional, :string, size: 70) # Bonuses, etc

      add(:region, :string, size: 100, null: false) # State
      add(:locality, :string, size: 100, null: false) # City
      add(:country, :string, size: 100, null: false) # USA (i think always)

      add(:work_hours, :string, size: 70, null: false) # Full time, part time, etc
      add(:employment_type, :string, size: 70, null: false) # Contract, Temp, permanent, etc.

      add(:start_date, :string, size: 70) # String
      add(:description_html, :string, size: 10_000, null: false) # HTML description of the job

      # Resources
      add(:job_source_url, :string, size: 255) # URL of company offering job
      add(:application_url, :string, size: 255, null: false) # Application URL. This will be created such that it autofills the users information
      add(:description_url, :string, size: 255, null: false) # JobG8 posting page
      add(:logo_url, :string, size: 255) # Logo for the ADVERTISER (not necessarily the company hiring)

      # Private details
      add(:job_type, :string, size: 20, null: false) # What kind of action for this job gets us paid? (APPLICATION, ATS, or TRAFFIC)
      add(:sell_price, :string, size: 20, null: false) # How much do we get paid for this link? (this will likely not be on route)
      add(:revenue_type, :string, size: 20, null: false) # How we get paid (Per application ("CPA") or per click ("CPC"))

      add(:advertiser_name, :string, size: 100, null: false) # Name of the advertiser
      add(:advertiser_type, :string, size: 100, null: false) # Type of the advertiser

      timestamps()
    end

    create(unique_index(:job_gate_listings, [:sender_reference]))

    # Table of classification names
    create table(:job_gate_classifications) do
      add(:name, :string, size: 100, null: false)
    end

    create(unique_index(:job_gate_classifications, [:name]))

    # Join table for job type classifications
    create table(:job_gate_classification_joiner) do
      add(:job_gate_sender_reference, references(:job_gate_listings, column: :sender_reference, type: :string, on_delete: :delete_all))
      add(:job_gate_classification_id, references(:job_gate_classifications, on_delete: :delete_all))
      add(:is_primary, :boolean, default: false)
    end
  end

  def down() do
    drop(table(:job_gate_classification_joiner))
    drop(table(:job_gate_classifications))
    drop(table(:job_gate_listings))
    drop(table(:job_gate_naming_transforms))
    drop(table(:job_gate_column_types))
  end
end
