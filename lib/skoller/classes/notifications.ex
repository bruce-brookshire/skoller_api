defmodule Skoller.Classes.Notifications do
  @moduledoc """
  A context module for class notifications.
  """

  alias Skoller.Notifications
  alias Skoller.Services.Notification
  alias Skoller.Devices
  alias Skoller.Notifications.ManualLogs

  @class_complete_category "Class.Complete"
  @manual_syllabus_category "Manual.NeedsSyllabus"

  @a_classmate "A classmate is setting up "
  @check_out " . Watch the assignments start rolling in your schedule 💯  👍  "

  @needs_syllabus_msg "It’s not too late to upload your syllabi on our website! Take a couple minutes to knock it out. Your class will love you for it 👌"

  def send_class_complete_notification(%{is_editable: true} = class) do
    devices = class.id
            |> Notifications.get_users_from_class()
            |> Enum.reduce([], &Devices.get_devices_by_user_id(&1.id) ++ &2)
    msg =  class |> class_complete_msg()
    
    devices |> Enum.each(&Notification.create_notification(&1.udid, &1.type, msg, @class_complete_category))
  end
  def send_class_complete_notification(_class), do: :ok

  def send_needs_syllabus_notifications() do
    users = Notifications.get_notification_enabled_needs_syllabus_users()
    |> Enum.reduce([], &Devices.get_devices_by_user_id(&1.id) ++ &2)

    ManualLogs.create_manual_log(Enum.count(users), @manual_syllabus_category, @needs_syllabus_msg)
    
    users
    |> Enum.each(&Notification.create_notification(&1.udid, &1.type, @needs_syllabus_msg, @manual_syllabus_category))
  end

  defp class_complete_msg(class) do
    @a_classmate <> class.name <> @check_out
  end
end