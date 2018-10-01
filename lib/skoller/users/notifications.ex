defmodule Skoller.Users.Notifications do
  @moduledoc """
  A context module for user notifications
  """

  alias Skoller.Users.Students
  alias Skoller.Devices
  alias Services.Notification

  @link_used_msg "More points earned! Someone just signed up for Skoller using your link. 🤩  "
  @link_used_category "SignupLink.Used"

  def send_link_used_notification(student_id) do
    user = Students.get_user_by_student_id(student_id)
    devices = Devices.get_devices_by_user_id(user.id)
    devices |> Enum.each(&Notification.create_notification(&1.udid, &1.type, @link_used_msg, @link_used_category))
  end
end