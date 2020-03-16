defmodule Skoller.Repo.Migrations.JobListings do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.Roles.Role
  alias Skoller.UserRoles.UserRole

  import Ecto.Query

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
      # JobG8 ID
      add(:sender_reference, :string, size: 30, null: false, primary_key: true, unique: true)

      # Job details
      # Company offering job
      add(:job_source, :string, size: 100)

      # What are you getting hired to do
      add(:position, :string, size: 70, null: false)

      # Min salary
      add(:salary_minimum, :string, size: 20)
      # Max salary
      add(:salary_maximum, :string, size: 20)
      # What do they get paid in
      add(:salary_currency, :string, size: 70, null: false)
      # What time period is the salary based over? salary / (salary_period, i.e. "year") <- here
      add(:salary_period, :string, size: 70, null: false)
      # Bonuses, etc
      add(:salary_additional, :string, size: 70)

      # State
      add(:region, :string, size: 100, null: false)
      # City
      add(:locality, :string, size: 100, null: false)
      # USA (i think always)
      add(:country, :string, size: 100, null: false)

      # Full time, part time, etc
      add(:work_hours, :string, size: 70, null: false)
      # Contract, Temp, permanent, etc.
      add(:employment_type, :string, size: 70, null: false)

      # String
      add(:start_date, :string, size: 70)
      # HTML description of the job
      add(:description_html, :string, size: 10_000, null: false)

      # Resources
      # URL of company offering job
      add(:job_source_url, :string, size: 255)
      # Application URL. This will be created such that it autofills the users information
      add(:application_url, :string, size: 255, null: false)
      # JobG8 posting page
      add(:description_url, :string, size: 255, null: false)
      # Logo for the ADVERTISER (not necessarily the company hiring)
      add(:logo_url, :string, size: 255)

      # Private details
      # What kind of action for this job gets us paid? (APPLICATION, ATS, or TRAFFIC)
      add(:job_type, :string, size: 20, null: false)
      # How much do we get paid for this link? (this will likely not be on route)
      add(:sell_price, :string, size: 20, null: false)
      # How we get paid (Per application ("CPA") or per click ("CPC"))
      add(:revenue_type, :string, size: 20, null: false)

      # Name of the advertiser
      add(:advertiser_name, :string, size: 100, null: false)
      # Type of the advertiser
      add(:advertiser_type, :string, size: 100, null: false)

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
      add(
        :job_listing_sender_reference,
        references(:job_gate_listings,
          column: :sender_reference,
          type: :string,
          on_delete: :delete_all
        )
      )

      add(
        :job_gate_classification_id,
        references(:job_gate_classifications, on_delete: :delete_all)
      )

      add(:is_primary, :boolean, default: false)
    end

    create table(:job_listing_user_actions) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:action, :string, size: 20, null: false)

      add(
        :job_listing_sender_reference,
        references(:job_gate_listings, column: :sender_reference, type: :string)
      )

      timestamps()
    end

    create table(:state_regions, primary_key: false) do
      add(:state_name, :string, size: 14)
      add(:region_name, :string, size: 9)
    end

    flush()

    Repo.insert_all("state_regions", generate_states())

    %Role{
      id: 600,
      name: "Job Listing Provider"
    }
    |> Repo.insert()
  end

  def down() do
    drop_if_exists(table(:job_listing_user_actions))
    drop_if_exists(table(:job_gate_classification_joiner))
    drop_if_exists(table(:job_gate_classifications))
    drop_if_exists(table(:job_gate_listings))
    drop_if_exists(table(:job_gate_naming_transforms))
    drop_if_exists(table(:job_gate_column_types))

    drop_if_exists(table(:state_regions))

    from(ur in UserRole)
    |> where([ur], ur.role_id == 600)
    |> Repo.delete_all()

    case Repo.get(Role, 600) do  
      nil -> nil
      role -> Repo.delete(role)
    end
  end

  defp generate_states(),
    do: [
      %{state_name: "Pennsylvania", region_name: "Northeast"},
      %{state_name: "Maine", region_name: "Northeast"},
      %{state_name: "North Dakota", region_name: "Midwest"},
      %{state_name: "South Carolina", region_name: "South"},
      %{state_name: "Hawaii", region_name: "West"},
      %{state_name: "Massachusetts", region_name: "Northeast"},
      %{state_name: "Missouri", region_name: "Midwest"},
      %{state_name: "West Virginia", region_name: "South"},
      %{state_name: "South Dakota", region_name: "Midwest"},
      %{state_name: "Arkansas", region_name: "South"},
      %{state_name: "Delaware", region_name: "South"},
      %{state_name: "Wyoming", region_name: "West"},
      %{state_name: "Washington", region_name: "West"},
      %{state_name: "Wisconsin", region_name: "Midwest"},
      %{state_name: "Mississippi", region_name: "South"},
      %{state_name: "Colorado", region_name: "West"},
      %{state_name: "Georgia", region_name: "South"},
      %{state_name: "North Carolina", region_name: "South"},
      %{state_name: "Idaho", region_name: "West"},
      %{state_name: "Nevada", region_name: "West"},
      %{state_name: "New Hampshire", region_name: "Northeast"},
      %{state_name: "Florida", region_name: "South"},
      %{state_name: "Utah", region_name: "West"},
      %{state_name: "Tennessee", region_name: "South"},
      %{state_name: "Kansas", region_name: "Midwest"},
      %{state_name: "Illinois", region_name: "Midwest"},
      %{state_name: "New York", region_name: "Northeast"},
      %{state_name: "Rhode Island", region_name: "Northeast"},
      %{state_name: "Indiana", region_name: "Midwest"},
      %{state_name: "Kentucky", region_name: "South"},
      %{state_name: "Oregon", region_name: "West"},
      %{state_name: "Texas", region_name: "South"},
      %{state_name: "Nebraska", region_name: "Midwest"},
      %{state_name: "Vermont", region_name: "Northeast"},
      %{state_name: "Alabama", region_name: "South"},
      %{state_name: "Michigan", region_name: "Midwest"},
      %{state_name: "Maryland", region_name: "South"},
      %{state_name: "Louisiana", region_name: "South"},
      %{state_name: "Alaska", region_name: "West"},
      %{state_name: "New Mexico", region_name: "West"},
      %{state_name: "Virginia", region_name: "South"},
      %{state_name: "Oklahoma", region_name: "South"},
      %{state_name: "Iowa", region_name: "Midwest"},
      %{state_name: "Ohio", region_name: "Midwest"},
      %{state_name: "Montana", region_name: "West"},
      %{state_name: "New Jersey", region_name: "Northeast"},
      %{state_name: "Arizona", region_name: "West"},
      %{state_name: "California", region_name: "West"},
      %{state_name: "Minnesota", region_name: "Midwest"},
      %{state_name: "Connecticut", region_name: "Northeast"}
    ]
end
