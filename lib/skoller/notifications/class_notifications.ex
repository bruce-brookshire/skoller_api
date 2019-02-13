defmodule Skoller.ClassNotifications do
  @moduledoc """
  A context module for sending class notifications.
  """

  alias Skoller.Classes.Class
  alias Skoller.Notifications
  alias Skoller.Services.Notification

  @days_of_week ["M", "T", "W", "R", "F", "S", "U"]

  def send_class_start_notifications(%Class{} = class) do
    class
    |> Notifications.get_class_start_notifications()
    |> Enum.each(&send_notifications(&1))
  end
  def send_class_start_notifications() do
    Enum.at(@days_of_week, Date.day_of_week(Date.utc_today()) - 1)
    |> Notifications.get_class_start_classes(5)
    |> Enum.each(&send_class_start_notifications(&1))
  end

  defp send_notifications(class_start) do
    Notification.create_notification(class_start.udid, class_start.type, get_message(class_start), "Class.Start", %{class_id: class_start.class.id})
  end

  defp get_message(class_start) do
    "Don't try to take on this class alone. AirDrop Skoller to your " <> class_start.class.name <> " classmates!"
  end
end