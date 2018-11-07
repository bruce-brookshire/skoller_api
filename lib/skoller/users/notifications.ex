defmodule Skoller.Users.Notifications do
  @moduledoc """
  A context module for user notifications
  """

  alias Skoller.Users.Students
  alias Skoller.Devices
  alias Skoller.Services.Notification
  alias Skoller.Notifications
  alias Skoller.Notifications.ManualLogs

  @link_used_msg "More points earned! Someone just signed up for Skoller using your link. 🤩  "
  @link_used_category "SignupLink.Used"
  @manual_custom_category "Manual.Custom"

  @doc """
  Sends a notification that a sign up link was used.
  """
  def send_link_used_notification(student_id) do
    user = Students.get_user_by_student_id(student_id)
    devices = Devices.get_devices_by_user_id(user.id)
    devices |> Enum.each(&Notification.create_notification(&1.udid, &1.type, @link_used_msg, @link_used_category))
  end

  @doc """
  Sends a custom notification to all users.
  """
  def send_custom_notification(msg) do
    devices = Notifications.get_notification_enabled_devices()

    ManualLogs.create_manual_log(Enum.count(devices),  @manual_custom_category, msg)
    
    devices
    |> Enum.each(&Notification.create_notification(&1.udid, &1.type, msg, @manual_custom_category))
  end
end