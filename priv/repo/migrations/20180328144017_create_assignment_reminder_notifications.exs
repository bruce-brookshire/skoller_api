defmodule Skoller.Repo.Migrations.CreateAssignmentReminderNotifications do
  use Ecto.Migration

  def change do
    create table(:assignment_reminder_notifications) do
      add :topic, :string
      add :message, :string, size: 150
      add :is_plural, :boolean, default: true, null: false

      timestamps()
    end

  end
end
