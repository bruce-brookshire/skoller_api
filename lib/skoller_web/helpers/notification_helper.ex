defmodule SkollerWeb.Helpers.NotificationHelper do
  
  alias Skoller.Repo
  alias SkollerWeb.Notification
  alias Skoller.Students.Student
  alias Skoller.Class.Assignment
  alias Skoller.Classes
  alias Skoller.Notifications
  alias Skoller.Devices

  @moduledoc """
  
  Contains helper functions for sending notifications.

  """

  @manual_syllabus_category "Manual.NeedsSyllabus"
  @manual_custom_category "Manual.Custom"
  @assignment_post "Assignment.Post"

  @in_s " in "

  @commented_on_s " commented on "

  @needs_syllabus_msg "It’s not too late to upload your syllabi on our website! Take a couple minutes to knock it out. Your class will love you for it 👌"

  def send_needs_syllabus_notifications() do
    users = Notifications.get_notification_enabled_needs_syllabus_users()
    |> Enum.reduce([], &Devices.get_devices_by_user_id(&1.id) ++ &2)

    Repo.insert(%Skoller.Notification.ManualLog{affected_users: Enum.count(users), notification_category: @manual_syllabus_category, msg: @needs_syllabus_msg})

    users
    |> Enum.each(&Notification.create_notification(&1.udid, @needs_syllabus_msg, @manual_syllabus_category))
  end

  def send_custom_notification(msg) do
    devices = Notifications.get_notification_enabled_devices()

    Repo.insert(%Skoller.Notification.ManualLog{affected_users: Enum.count(devices), notification_category: @manual_custom_category, msg: msg})
  
    devices
    |> Enum.each(&Notification.create_notification(&1.udid, msg, @manual_custom_category))
  end

  def send_assignment_post_notification(post, student_id) do
    student = Repo.get!(Student, student_id)
    assignment = Repo.get!(Assignment, post.assignment_id)
    class = Classes.get_class_by_id!(assignment.class_id)
    Notifications.get_assignment_post_devices_by_assignment(student_id, post.assignment_id)
    |> Enum.each(&Notification.create_notification(&1.udid, build_assignment_post_msg(post, student, assignment, class), @assignment_post))
  end
  
  defp build_assignment_post_msg(post, student, assignment, class) do
    student.name_first <> " " <> student.name_last <> @commented_on_s <> assignment.name <> @in_s <> class.name <> ": " <> post.post
  end
end