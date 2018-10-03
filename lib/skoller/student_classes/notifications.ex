defmodule Skoller.StudentClasses.Notifications do
  @moduledoc """
  Defines notifications based on student classes
  """

  alias Skoller.Devices
  alias Skoller.Services.Notification
  alias Skoller.EmailTypes

  @no_classes_id 100

  def send_no_classes_notification(students) do
    email_type = EmailTypes.get!(@no_classes_id)
    students_with_devices = students |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(List.first(&1.users).id)))
    students_with_devices |> Enum.each(&Enum.each(&1.devices, fn(x) -> Notification.create_notification(x.udid, x.type, create_no_class_msg(), email_type.category) end))
  end

  defp create_no_class_msg() do
    "Looks like you’re not in any classes…Add them today so you don’t get behind! 👍"
  end
end