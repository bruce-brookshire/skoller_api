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
    |> Enum.each(&send_notifications(&1, class))
  end
  def send_class_start_notifications() do
    Enum.at(@days_of_week, Date.day_of_week(Date.utc_today()) - 1)
    |> Notifications.get_class_start_classes(5)
    |> Enum.each(&send_class_start_notifications(&1))
  end

  defp send_notifications(class_device, class_obj) do
    Notification.create_notification(class_device.udid, class_device.type, get_message(class_obj), "Class.Start", %{class_id: class_device.class_id})
  end

  defp get_message(class_obj) do
    "Don't try to take on this class alone. AirDrop Skoller to your " <> class_obj.name <> " classmates!"
  end
end