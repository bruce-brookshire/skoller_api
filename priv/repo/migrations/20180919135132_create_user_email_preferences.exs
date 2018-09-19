defmodule Skoller.Repo.Migrations.CreateUserEmailPreferences do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:user_email_preferences) do
      add :is_unsubscribed, :boolean, default: false, null: false
      add :is_no_classes_email, :boolean, default: false, null: false
      add :is_class_setup_email, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:user_email_preferences, [:user_id])
  end
end
