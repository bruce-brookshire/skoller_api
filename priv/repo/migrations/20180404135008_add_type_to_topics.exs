defmodule Skoller.Repo.Migrations.AddTypeToTopics do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:assignment_reminder_notification_topics) do
      add :name, :string
    end

    drop constraint("assignment_reminder_notifications", "assignment_reminder_notifications_assignment_reminder_notificat")
    alter table(:assignment_reminder_notifications) do
      modify :assignment_reminder_notification_topic_id, references(:assignment_reminder_notification_topics, on_delete: :delete_all)
    end
  end
end
