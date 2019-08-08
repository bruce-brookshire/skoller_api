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

  @no_classes "Don't take on this semester alone! Join a class and let Skoller get you organized."
  @needs_setup "Kickstart an easier semester! All you need to do is drop your syllabus for "
  @grow_community_1 "You're missing out... Unlock hidden community features for "
  @grow_community_2 " when you share Skoller with your classmates."
  @second_class "Let us organize ALL your assignments. Join your 2nd class!"

  def send_no_classes_notification(students, email_type) do
    students_with_devices =
      students
      |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(List.first(&1.users).id)))

    students_with_devices
    |> Enum.each(
      &Enum.each(&1.devices, fn x ->
        Notification.create_notification(x.udid, x.type, @no_classes, email_type.category)
      end)
    )
  end

  def send_needs_setup_notification(user_class_info, email_type) do
    user_class_info
    |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(&1.user.id)))
    |> Enum.each(
      &Enum.each(&1.devices, fn x ->
        Notification.create_notification(
          x.udid,
          x.type,
          @needs_setup <> &1.class_name,
          email_type.category
        )
      end)
    )
  end

  def send_grow_community_notification(user_class_info, email_type) do
    user_class_info
    |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(&1.user.id)))
    |> Enum.each(
      &Enum.each(&1.devices, fn x ->
        Notification.create_notification(
          x.udid,
          x.type,
          @grow_community_1 <> &1.class_name <> @grow_community_2,
          email_type.category
        )
      end)
    )
  end

  def send_join_second_class_notification(users, email_type) do
    users
    |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(&1.id)))
    |> Enum.each(
      &Enum.each(&1.devices, fn x ->
        Notification.create_notification(x.udid, x.type, @second_class, email_type.category)
      end)
    )
  end

  def send_link_used_notification(student_class, class) do
    user = Students.get_user_by_student_id(student_class.student_id)
    devices = Devices.get_devices_by_user_id(user.id)

    devices
    |> Enum.each(
      &Notification.create_notification(
        &1.udid,
        &1.type,
        @link_used_msg <> class.name <> @link_used_msg2,
        @link_used_category
      )
    )
  end
end
