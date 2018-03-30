defmodule ClassnavapiWeb.Assignment.ReminderNotificationView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Assignments
  alias ClassnavapiWeb.Assignment.ReminderNotificationView

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
      is_today: Assignments.get_is_today(reminder_notification.topic),
      is_plural: reminder_notification.is_plural
    }
  end
end
