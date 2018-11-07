defmodule Skoller.Classes.Notifications do
  @moduledoc """
  A context module for class notifications.
  """

  alias Skoller.Repo
  alias Skoller.Notifications
  alias Skoller.Services.Notification
  alias Skoller.Devices
  alias Skoller.Notifications.ManualLogs

  @class_complete_category "Class.Complete"
  @manual_syllabus_category "Manual.NeedsSyllabus"

  @class_complete "We didn't find any assignments on the syllabus. Be sure to add assignments on the app throughout the semester so you and your classmates can keep up. 💯"  
  @is_ready " is ready!"
  @we_created "We created"
  @from_syllabus "from the class syllabus. Any new assignments or schedule changes are up to you and your classmates. 💯"
  @one_assign_class_complete "assignment " <> @from_syllabus
  @multiple_assign_class_complete "assignments " <> @from_syllabus

  @needs_syllabus_msg "It’s not too late to upload your syllabi on our website! Take a couple minutes to knock it out. Your class will love you for it 👌"

  def send_class_complete_notification(%{is_editable: true} = class) do
    devices = class.id
            |> Notifications.get_users_from_class()
            |> Enum.reduce([], &Devices.get_devices_by_user_id(&1.id) ++ &2)
    class = class |> Repo.preload([:assignments])
    msg = class.assignments |> class_complete_msg()
    
    devices |> Enum.each(&Notification.create_notification(&1.udid, &1.type, %{title: class.name <> @is_ready, body: msg}, @class_complete_category))
  end
  def send_class_complete_notification(_class), do: :ok

  def send_needs_syllabus_notifications() do
    users = Notifications.get_notification_enabled_needs_syllabus_users()
    |> Enum.reduce([], &Devices.get_devices_by_user_id(&1.id) ++ &2)

    ManualLogs.create_manual_log(Enum.count(users), @manual_syllabus_category, @needs_syllabus_msg)
    
    users
    |> Enum.each(&Notification.create_notification(&1.udid, &1.type, @needs_syllabus_msg, @manual_syllabus_category))
  end

  defp class_complete_msg(assignments) do
    case Enum.count(assignments) do
      0 -> @class_complete
      1 -> @we_created <> " 1 " <> @one_assign_class_complete
      num -> @we_created <> " " <> to_string(num) <> " " <> @multiple_assign_class_complete
    end
  end
end