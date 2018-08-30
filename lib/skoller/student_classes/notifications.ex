defmodule Skoller.StudentClasses.Notifications do
  @moduledoc """
  Defines notifications based on student classes
  """

  alias Skoller.Devices
  alias Skoller.Notification

  @no_class_category "Class.None"

  def send_no_classes_notification(students) do
    students_with_devices = students |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(List.first(&1.users).id)))
    students_with_devices |> Enum.each(&Enum.each(&1.devices, fn(x) -> Notification.create_notification(x.udid, create_no_class_msg(), @no_class_category) end))
  end

  defp create_no_class_msg() do
    "Looks like you’re not in any classes…Add them today so you don’t get behind! 👍"
  end
end