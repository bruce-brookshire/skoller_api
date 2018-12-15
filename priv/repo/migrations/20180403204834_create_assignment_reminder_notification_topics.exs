defmodule Skoller.Repo.Migrations.CreateAssignmentReminderNotificationTopics do
  @moduledoc false
  use Ecto.Migration

  def up do
    create table(:assignment_reminder_notification_topics) do
      add :topic, :string

      timestamps()
    end
    drop table(:assignment_reminder_notifications)
    create table(:assignment_reminder_notifications) do
      add :assignment_reminder_notification_topic_id, references(:assignment_reminder_notification_topics, on_delete: :nothing)
      add :message, :string, size: 150
      add :is_plural, :boolean, default: true, null: false

      timestamps()
    end
    create index(:assignment_reminder_notifications, [:assignment_reminder_notification_topic_id])
  end
end
