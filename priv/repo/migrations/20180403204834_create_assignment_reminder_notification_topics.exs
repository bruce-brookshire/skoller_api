defmodule Classnavapi.Repo.Migrations.CreateAssignmentReminderNotificationTopics do
  use Ecto.Migration

  alias Classnavapi.Repo

  def up do
    create table(:assignment_reminder_notification_topics) do
      add :topic, :string

      timestamps()
    end
    flush()
    Repo.insert!(%Classnavapi.Assignments.ReminderNotification.Topic{id: 100, topic: "Assignment.Reminder.Today"})
    Repo.insert!(%Classnavapi.Assignments.ReminderNotification.Topic{id: 200, topic: "Assignment.Reminder.Tomorrow"})
    Repo.insert!(%Classnavapi.Assignments.ReminderNotification.Topic{id: 300, topic: "Assignment.Reminder.Future"})
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
