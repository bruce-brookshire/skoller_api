defmodule Skoller.Repo.Migrations.AddTypeToTopics do
  use Ecto.Migration

  alias Skoller.Repo

  def change do
    alter table(:assignment_reminder_notification_topics) do
      add :name, :string
    end

    drop constraint("assignment_reminder_notifications", "assignment_reminder_notifications_assignment_reminder_notificat")
    alter table(:assignment_reminder_notifications) do
      modify :assignment_reminder_notification_topic_id, references(:assignment_reminder_notification_topics, on_delete: :delete_all)
    end

    flush()
    Repo.delete!(%Skoller.Assignments.ReminderNotification.Topic{id: 100, topic: "Assignment.Reminder.Today"})
    Repo.delete!(%Skoller.Assignments.ReminderNotification.Topic{id: 200, topic: "Assignment.Reminder.Tomorrow"})
    Repo.delete!(%Skoller.Assignments.ReminderNotification.Topic{id: 300, topic: "Assignment.Reminder.Future"})

    Repo.insert!(%Skoller.Assignments.ReminderNotification.Topic{id: 100, topic: "Assignment.Reminder.Today", name: "Today"})
    Repo.insert!(%Skoller.Assignments.ReminderNotification.Topic{id: 200, topic: "Assignment.Reminder.Tomorrow", name: "Tomorrow"})
    Repo.insert!(%Skoller.Assignments.ReminderNotification.Topic{id: 300, topic: "Assignment.Reminder.Future", name: "Future"})
  end
end
