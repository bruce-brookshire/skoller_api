defmodule SkollerWeb.Assignment.ReminderNotificationView do
  use SkollerWeb, :view

  alias Skoller.Assignments
  alias SkollerWeb.Assignment.ReminderNotificationView
  alias SkollerWeb.Assignment.ReminderNotification.TopicView

  def render("index.json", %{reminder_notifications: reminder_notifications}) do
    render_many(reminder_notifications, ReminderNotificationView, "reminder_notification.json")
  end

  def render("show.json", %{reminder_notification: reminder_notification}) do
    render_one(reminder_notification, ReminderNotificationView, "reminder_notification.json")
  end

  def render("reminder_notification.json", %{reminder_notification: reminder_notification}) do
    %{
      id: reminder_notification.id,
      message: reminder_notification.message,
      topic: render_one(
        Assignments.get_assignment_message_topic_by_id!(
        reminder_notification.assignment_reminder_notification_topic_id), 
        TopicView, "topic.json"),
      is_plural: reminder_notification.is_plural
    }
  end
end
