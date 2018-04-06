defmodule Skoller.Repo.Migrations.CreateManualNotificationLogs do
  use Ecto.Migration

  def change do
    create table(:manual_notification_logs) do
      add :notification_category, :string
      add :affected_users, :integer

      timestamps()
    end

  end
end
