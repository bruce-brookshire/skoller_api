defmodule Skoller.Repo.Migrations.SkollerInsights do
  use Ecto.Migration

  import Ecto.Query

  alias Skoller.Repo
  alias Skoller.Roles.Role
  alias Skoller.UserRoles.UserRole

  def up do
    create table(:org_schools) do
      add(:organization_id, references(:organizations))
      add(:school_id, references(:schools))
    end

    alter table(:organizations) do
      add(:color, :string, size: 10)
      add(:logo_url, :string)
    end

    create table(:org_groups) do
      add(:organization_id, references(:organizations))
      add(:name, :string)
    end

    # Owners
    create table(:org_members) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:organization_id, references(:organizations, on_delete: :delete_all))
    end
    
    create table(:org_owners) do
      add(:organization_id, references(:organizations))
      add(:user_id, references(:users, on_delete: :delete_all))
    end

    create table(:org_group_owners) do
      add(:org_group_id, references(:org_groups, on_delete: :delete_all))
      add(:org_member_id, references(:org_members, on_delete: :delete_all))
    end

    # Students
    create table(:org_students) do
      add(:organization_id, references(:organizations, on_delete: :delete_all))
      add(:student_id, references(:students, on_delete: :delete_all))
    end

    create table(:org_group_students) do
      add(:org_group_id, references(:org_groups, on_delete: :delete_all))
      add(:org_student_id, references(:org_students, on_delete: :delete_all))
    end

    # Watchlists
    create table(:org_owner_watchlist_items) do
      add(:org_owner_id, references(:org_owners, on_delete: :delete_all))
      add(:org_student_id, references(:org_students, on_delete: :delete_all))
    end

    create table(:org_group_owner_watchlist_items) do
      add(:org_group_owner_id, references(:org_group_owners, on_delete: :delete_all))
      add(:org_group_student_id, references(:org_group_students, on_delete: :delete_all))
    end

    create table(:student_org_invitations) do
      add(:student_id, references(:students))
      add(:organization_id, references(:organizations))
    end

    create(unique_index(:org_owners, [:user_id, :organization_id]))
    create(unique_index(:org_group_owners, [:org_member_id, :org_group_id]))
    create(unique_index(:org_students, [:organization_id, :student_id]))
    create(unique_index(:org_group_students, [:org_student_id, :org_group_id]))

    %Role{
      id: 700,
      name: "Insights User"
    }
    |> Repo.insert()
  end

  def down do
    alter table(:organizations) do
      remove(:color)
      remove(:logo_url)
    end

    from(ur in UserRole)
    |> where([ur], ur.role_id == 600)
    |> Repo.delete_all()

    case Repo.get(Role, 600) do  
      nil -> nil
      role -> Repo.delete(role)
    end

    drop(table(:org_schools))
    drop(table(:org_owner_watchlist_items))
    drop(table(:org_group_owner_watchlist_items))
    drop(table(:org_group_students))
    drop(table(:org_students))
    drop(table(:org_group_owners))
    drop(table(:org_owners))
    drop(table(:org_groups))
    drop(table(:org_members))
    drop(table(:student_org_invitations))
  end
end
