defmodule Skoller.Users.Notifications do
  @moduledoc """
  A context module for user notifications
  """

  alias Skoller.Users.Students
  alias Skoller.Devices
  alias Services.Notification

  @link_used_msg "🤩 Someone just signed up for Skoller using your link!"
  @link_used_category "SignupLink.Used"

  def send_link_used_notification(student_id) do
    user = Students.get_user_by_student_id(student_id)
    device = Devices.get_devices_by_user_id(user.id)
    Notification.create_notification(device.udid, device.type, @link_used_msg, @link_used_category)
  end
end