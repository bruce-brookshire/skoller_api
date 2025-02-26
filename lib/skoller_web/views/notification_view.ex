defmodule SkollerWeb.NotificationView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.NotificationView

  def render("index.json", %{notifications: notifications}) do
    render_many(notifications, NotificationView, "notification.json")
  end

  def render("notification.json", %{notification: notification}) do
    %{
      affected_users: notification.affected_users,
      notification_category: notification.notification_category,
      msg: notification.msg,
      inserted_at: notification.inserted_at
    }
  end
end
