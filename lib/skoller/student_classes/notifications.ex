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

  @needs_setup "Kickstart an easier semester! All you need to do is drop your syllabus for "
  @grow_community_1 "You're missing out... Unlock hidden community features for "
  @grow_community_2 " when you share Skoller with your classmates."
  @grow_community_org "The more you share, the more $$$ you earn for your philanthropy! Share with classmates to unlock hidden features & raise more money"
  @second_class "Let us organize ALL your assignments. Join your 2nd class!"
  @second_class_org "We'll organize ALL your assignments for you. Join your 2nd class and share to raise more $$$!"

  @aopi_foundation "Arthritis Foundation"
  @asa_foundation "Alpha Sigma Alpha Foundation"

  @aopi_name "AOII"
  @asa_name "ASA"

  # No classes notifications
  def send_no_classes_notification(
        %{
          devices: devices,
          org_name: org_name,
          opts: %{org_name: org_name}
        },
        email_type
      ) do
    message =
      case org_name do
        @aopi_name ->
          "You're so close! Sign up & join your first class on Skoller to earn a $1 donation to the " <>
            @aopi_foundation <> "!"

        @asa_name ->
          "You're so close! Sign up & join your first class on Skoller to earn a $1 donation to the " <>
            @asa_foundation <> "!"

        _ ->
          "Don't take on this semester alone! Join a class and let Skoller get you organized."
      end

    create_notifications(devices, message, email_type.category)
  end

  def send_no_classes_notification(user_info, email_type) do
    user_info
    |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(&1.user.id)))
    |> Enum.each(&send_no_classes_notification(&1, email_type))
  end

  # Needs setup notifications
  def send_needs_setup_notification(
        %{
          devices: devices,
          opts: %{class_name: class_name, org_name: nil}
        },
        email_type
      ),
      do: create_notifications(devices, @needs_setup <> class_name, email_type.category)

  def send_needs_setup_notification(
        %{
          devices: devices,
          opts: %{class_name: class_name, org_name: _}
        },
        email_type
      ),
      do:
        create_notifications(
          devices,
          "Halfway there! You joined " <> class_name <> ", now just submit the syllabus",
          email_type.category
        )

  def send_needs_setup_notification(user_info, email_type) do
    user_info
    |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(&1.user.id)))
    |> Enum.each(&send_needs_setup_notification(&1, email_type))
  end

  # Grow community notifications
  def send_grow_community_notification(
        %{
          devices: devices,
          opts: %{class_name: class_name, org_name: nil}
        },
        email_type
      ),
      do:
        create_notifications(
          devices,
          @grow_community_1 <> class_name <> @grow_community_2,
          email_type.category
        )

  def send_grow_community_notification(
        %{
          devices: devices,
          opts: %{class_name: _, org_name: _}
        },
        email_type
      ),
      do:
        create_notifications(
          devices,
          @grow_community_org,
          email_type.category
        )

  def send_grow_community_notification(user_info, email_type) do
    user_info
    |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(&1.user.id)))
    |> Enum.each(&send_grow_community_notification(&1, email_type))
  end

  # Needs setup notifications
  def send_join_second_class_notification(
        %{
          devices: devices,
          opts: %{class_name: class_name, org_name: nil}
        },
        email_type
      ),
      do: create_notifications(devices, @second_class <> class_name, email_type.category)

  def send_join_second_class_notification(
        %{
          devices: devices,
          opts: %{class_name: _, org_name: _}
        },
        email_type
      ),
      do: create_notifications(devices, @second_class_org, email_type.category)

  # Join second class
  def send_join_second_class_notification(user_info, email_type) do
    user_info
    |> Enum.map(&Map.put(&1, :devices, Devices.get_devices_by_user_id(&1.user.id)))
    |> Enum.each(&send_join_second_class_notification(&1, email_type))
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

  defp create_notifications(devices, message, category) do
    devices
    |> Enum.each(
      &Notification.create_notification(
        &1.udid,
        &1.type,
        message,
        category
      )
    )
  end
end
