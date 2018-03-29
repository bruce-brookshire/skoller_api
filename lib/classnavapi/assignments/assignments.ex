defmodule Classnavapi.Assignments do

  alias Classnavapi.Repo
  alias Classnavapi.Assignments.ReminderNotification

  import Ecto.Query

  @today_topic "Assignment.Reminder.Today"
  @future_topic "Assignment.Reminder.Future"

  @default_message_today_single "You have 1 assignment due today. Check it out!"
  @default_message_today_mult "You have [num] assignments due today. Check them out!"
  @default_message_future_single "You have 1 assignment coming up. Check it out!"
  @default_message_future_mult "You have [num] assignments coming up. Check them out!"

  def get_assignment_reminder(num, @today_topic) do
    get_assignment_reminder(num, @today_topic, :today)
  end
  def get_assignment_reminder(num, @future_topic) do
    get_assignment_reminder(num, @future_topic, :future)
  end

  def add_assignment_message(%{"reminder_message" => params}) do
    params = params |> Map.put("topic", get_topic(params))
    ReminderNotification.changeset(%ReminderNotification{}, params)
    |> Repo.insert()
  end

  def get_assignment_messages() do
    Repo.all(ReminderNotification)
  end

  def get_is_today(topic) do
    topic == @today_topic
  end

  defp get_assignment_reminder(num, topic, atom) do
    messages = get_messages(topic, num)

    case messages |> get_random_message() do
      nil -> get_default(atom, num)
      message -> message
    end 
  end

  defp get_messages(topic, num) when num > 1 do
    from(rn in ReminderNotification)
    |> where([rn], rn.topic == ^topic and rn.is_plural == true)
    |> Repo.all()
  end
  defp get_messages(topic, _num) do
    from(rn in ReminderNotification)
    |> where([rn], rn.topic == ^topic and rn.is_plural == false)
    |> Repo.all()
  end

  defp get_default(:today, num) when num > 1, do: @default_message_today_mult
  defp get_default(:today, _num), do: @default_message_today_single
  defp get_default(:future, num) when num > 1, do: @default_message_future_mult
  defp get_default(:future, _num), do: @default_message_future_single

  defp get_topic(%{"is_today" => true}), do: @today_topic
  defp get_topic(%{"is_today" => false}), do: @future_topic

  defp get_random_message([]), do: nil
  defp get_random_message(messages) do
    index = messages
            |> Enum.count() 
            |> :rand.uniform()
            |> Kernel.-(1)
    msg = messages |> Enum.at(index)
    msg.message
  end
end