defmodule Classnavapi.Assignments do

  alias Classnavapi.Repo
  alias Classnavapi.Assignments.ReminderNotification

  import Ecto.Query

  @today_topic "Assignment.Reminder.Today"
  @future_topic "Assignment.Reminder.Future"

  @default_message_today "You have [num] assignments due today. Check them out!"
  @default_message_future "You have [num] assignments coming up. Check them out!"

  def get_assignment_reminder(:today) do
    get_assignment_reminder(@today_topic, @default_message_today)
  end

  def get_assignment_reminder(:future) do
    get_assignment_reminder(@future_topic, @default_message_future)
  end

  defp get_assignment_reminder(topic, default) do
    assignments = from(rn in ReminderNotification)
    |> where([rn], rn.topic == ^topic)
    |> Repo.all()

    case assignments |> get_random_message() do
      nil -> default
      message -> message
    end 
  end

  defp get_random_message([]), do: nil
  defp get_random_message(assignments) do
    
  end
end