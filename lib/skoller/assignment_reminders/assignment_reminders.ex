defmodule Skoller.AssignmentReminders do
  @moduledoc """
  A context module for assignment reminders.
  """

  alias Skoller.Repo
  alias Skoller.Assignments.ReminderNotification
  alias Skoller.Assignments.ReminderNotification.Topic

  import Ecto.Query

  @today_topic 100
  @tomorrow_topic 200
  @future_topic 300

  @default_message_today_single "You have 1 assignment due today. Check it out!"
  @default_message_today_mult "You have [num] assignments due today. Check them out!"
  @default_message_tomorrow_single "You have 1 assignment tomorrow. Check it out!"
  @default_message_tomorrow_mult "You have [num] assignments tomorrow. Check them out!"
  @default_message_future_single "You have 1 assignment in the next [days] days. Check it out!"
  @default_message_future_mult "You have [num] assignments in the next [days] days. Check them out!"

  @doc """
  Gets an assignment reminder message based on the number of assignments and the topic.

  ## Topics
   * Today `100`
   * Tomorrow `200`
   * Future `300`

  ## Defaults
  | Num | Topic    | Message                                                             |
  | --- | -------- | ------------------------------------------------------------------- |
  | 1   | Today    | You have 1 assignment due today. Check it out!                      |
  | > 1 | Today    | You have [num] assignments due today. Check them out!               |
  | 1   | Tomorrow | You have 1 assignment tomorrow. Check it out!                       |
  | > 1 | Tomorrow | You have [num] assignments tomorrow. Check them out!                |
  | 1   | Future   | You have 1 assignment in the next [days] days. Check it out!        |
  | > 1 | Future   | You have [num] assignments in the next [days] days. Check them out! |

  ## Returns
  `String`
  """
  def get_assignment_reminder(num, topic) do
    messages = get_messages(topic, num)

    case messages |> get_random_message() do
      nil -> get_default(topic, num)
      message -> message
    end 
  end

  @doc """
  Creates a reminder message.

  ## Returns
  `{:ok, Skoller.Assignments.ReminderNotification}` or `{:error, changeset}`
  """
  def add_assignment_message(%{"reminder_message" => params}) do
    ReminderNotification.changeset(%ReminderNotification{}, params)
    |> Repo.insert()
  end

  @doc """
  Gets all reminder messages

  ## Returns
  `[Skoller.Assignments.ReminderNotification]` or `[]`
  """
  def get_assignment_messages() do
    Repo.all(ReminderNotification)
  end

  @doc """
  Deletes a reminder message.

  ## Returns
  `{:ok, Skoller.Assignments.ReminderNotification}` or `{:error, changeset}`
  """
  def delete_assignment_messages(id) do
    Repo.get!(ReminderNotification, id)
    |> Repo.delete()
  end

  @doc """
  Gets the assignment reminder notification topics.

  ## Returns
  `[Skoller.Assignments.ReminderNotification.Topic]` or `[]`
  """
  def get_assignment_message_topics() do
    Repo.all(Topic)
  end

  @doc """
  Gets an assignment reminder notification topic by id.

  ## Returns
  `Skoller.Assignments.ReminderNotification.Topic` or raises
  """
  def get_assignment_message_topic_by_id!(id) do
    Repo.get!(Topic, id)
  end

  #Gets messages based on topic and num.
  defp get_messages(topic, num) when num > 1 do
    from(rn in ReminderNotification)
    |> where([rn], rn.assignment_reminder_notification_topic_id == ^topic and rn.is_plural == true)
    |> Repo.all()
  end
  defp get_messages(topic, _num) do
    from(rn in ReminderNotification)
    |> where([rn], rn.assignment_reminder_notification_topic_id == ^topic and rn.is_plural == false)
    |> Repo.all()
  end

  #Gets default message.
  defp get_default(@today_topic, num) when num > 1, do: @default_message_today_mult
  defp get_default(@today_topic, _num), do: @default_message_today_single
  defp get_default(@tomorrow_topic, num) when num > 1, do: @default_message_tomorrow_mult
  defp get_default(@tomorrow_topic, _num), do: @default_message_tomorrow_single
  defp get_default(@future_topic, num) when num > 1, do: @default_message_future_mult
  defp get_default(@future_topic, _num), do: @default_message_future_single

  #Gets a random message from a list of messages.
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