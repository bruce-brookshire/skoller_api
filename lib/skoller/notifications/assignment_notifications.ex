defmodule Skoller.AssignmentNotifications do
  @moduledoc """
  A context module for sending assignment notifications.
  """

  alias Skoller.Assignments
  alias Skoller.Notifications
  alias SkollerWeb.Notification

  @assignment_reminder_today_category 100
  @assignment_reminder_tomorrow_category 200
  @assignment_reminder_future_category 300

  def send_assignment_reminder_notifications(time) do
    time 
    |> Notifications.get_assignment_reminders(:today)
    |> Enum.each(&send_notifications(&1, :today))

    time
    |> Notifications.get_assignment_reminders(:future)
    |> Enum.each(&send_notifications(&1, :future))
  end

  defp send_notifications(assignment, atom) do
    Notification.create_notification(assignment.udid, get_message(assignment, atom), get_topic(atom, assignment.days).topic)
  end

  defp get_message(assignment, atom) do
    Assignments.get_assignment_reminder(assignment.count, get_topic(atom, assignment.days).id)
    |> String.replace("[num]", assignment.count |> to_string())
    |> String.replace("[days]", assignment.days |> to_string())
  end

  defp get_topic(:today, _days), do: Assignments.get_assignment_message_topic_by_id!(@assignment_reminder_today_category)
  defp get_topic(:future, 1), do: Assignments.get_assignment_message_topic_by_id!(@assignment_reminder_tomorrow_category)
  defp get_topic(:future, _days), do: Assignments.get_assignment_message_topic_by_id!(@assignment_reminder_future_category)
end