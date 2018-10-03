defmodule Skoller.StudentClasses.Notifications do
  @moduledoc """
  Defines notifications based on student classes
  """

  alias Skoller.Devices
  alias Skoller.Services.Notification
  alias Skoller.EmailTypes
  alias Skoller.Users.Students

  @no_classes_id 100
  @link_used_msg "More points earned! Someone just joined "
  @link_used_msg2 " using your link. 🤩  "
  @link_used_category "SignupLink.Used"

  def send_no_classes_notification(students) do
    email_type = EmailTypes.get!(@no_classes_id)
    students_with_devices = students |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(List.first(&1.users).id)))
    students_with_devices |> Enum.each(&Enum.each(&1.devices, fn(x) -> Notification.create_notification(x.udid, x.type, create_no_class_msg(), email_type.category) end))
  end

  def send_link_used_notification(student_class, class) do
    user = Students.get_user_by_student_id(student_class.student_id)
    devices = Devices.get_devices_by_user_id(user.id)
    devices |> Enum.each(&Notification.create_notification(&1.udid, &1.type, @link_used_msg <> class.name <> @link_used_msg2, @link_used_category))
  end

  defp create_no_class_msg() do
    "Looks like you’re not in any classes…Add them today so you don’t get behind! 👍"
  end
end