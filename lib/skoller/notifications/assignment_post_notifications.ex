defmodule Skoller.AssignmentPostNotifications do
  @moduledoc """
  A context module for assignment post notificaitons
  """

  alias Skoller.Students
  alias Skoller.Assignments
  alias Skoller.Classes
  alias Skoller.Notifications
  alias Skoller.Services.Notification

  @assignment_post "Assignment.Post"
  
  @in_s " in "

  @commented_on_s " commented on "

  def send_assignment_post_notification(post, student_id) do
    student = Students.get_student_by_id!(student_id)
    assignment = Assignments.get_assignment_by_id!(post.assignment_id)
    class = Classes.get_class_by_id!(assignment.class_id)
    Notifications.get_assignment_post_devices_by_assignment(student_id, post.assignment_id)
    |> Enum.each(&Notification.create_notification(&1.udid, &1.type, build_assignment_post_msg(post, student, assignment, class), @assignment_post))
  end
  
  defp build_assignment_post_msg(post, student, assignment, class) do
    student.name_first <> " " <> student.name_last <> @commented_on_s <> assignment.name <> @in_s <> class.name <> ": " <> post.post
  end
end