defmodule Skoller.StudentClasses.Notifications do
  @moduledoc """
  Defines notifications based on student classes
  """

  alias Skoller.Devices
  alias Skoller.Services.Notification
  alias Skoller.Users.Students

  @link_used_msg "More points earned! Someone just joined "
  @link_used_msg2 " using your link. 🤩  "
  @link_used_category "SignupLink.Used"
  @needs_setup "Get the most of our Skoller. Finish setting up your classes 👍 "
  @no_classes "Looks like you’re not in any classes…Add them today so you don’t get behind! 👍"

  def send_no_classes_notification(students, email_type) do
    students_with_devices = students |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(List.first(&1.users).id)))
    students_with_devices |> Enum.each(&Enum.each(&1.devices, fn(x) -> Notification.create_notification(x.udid, x.type, @no_classes, email_type.category) end))
  end

  def send_needs_setup_notification(students, email_type) do
    students_with_devices = students |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(List.first(&1.users).id)))
    students_with_devices |> Enum.each(&Enum.each(&1.devices, fn(x) -> Notification.create_notification(x.udid, x.type, @needs_setup, email_type.category) end))
  end

  def send_link_used_notification(student_class, class) do
    user = Students.get_user_by_student_id(student_class.student_id)
    devices = Devices.get_devices_by_user_id(user.id)
    devices |> Enum.each(&Notification.create_notification(&1.udid, &1.type, @link_used_msg <> class.name <> @link_used_msg2, @link_used_category))
  end
end