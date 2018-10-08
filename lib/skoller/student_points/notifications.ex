defmodule Skoller.StudentPoints.Notifications do
  @moduledoc """
  A context module for sending notifications triggered off points.
  """

  alias Skoller.Devices
  alias Skoller.Services.Notification

  @notification_text "You've earned 1,000 points! Check your email to receive a prize from Skoller 😎 "

  def send_one_thousand_points_notification(user, email_type) do
    Devices.get_devices_by_user_id(user.id)
    |> Enum.each(&Notification.create_notification(&1.udid, &1.type, @notification_text, email_type.category))
  end
end