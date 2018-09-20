defmodule Skoller.Repo.Migrations.CreateUserEmailPreferences do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_unsubscribed, :boolean, default: false, null: false
    end
    create table(:email_types) do
      add :name, :string

      timestamps()
    end
    create table(:user_email_preferences) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :email_type_id, references(:email_types, on_delete: :delete_all)
      add :is_unsubscribed, :boolean, default: false, null: false

      timestamps()
    end

    create index(:user_email_preferences, [:user_id])
    create index(:user_email_preferences, [:email_type_id])
    create unique_index(:user_email_preferences, [:user_id, :email_type_id], name: :user_email_preferences_unique_index)
    create unique_index(:email_types, [:name])

    flush()

    Skoller.Repo.insert!(%Skoller.EmailTypes.EmailType{name: "No Classes Email"})
    Skoller.Repo.insert!(%Skoller.EmailTypes.EmailType{name: "Class Setup Email"})
  end
end
