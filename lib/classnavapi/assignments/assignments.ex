defmodule Classnavapi.Assignments do

  alias Classnavapi.Repo
  alias Classnavapi.Assignments.ReminderNotification
  alias Classnavapi.Assignments.ReminderNotification.Topic
  alias Classnavapi.Assignment.Post
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class

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

  def get_student_assignment_posts(student_id) do
    from(post in Post)
    |> join(:inner, [post], assign in Assignment, assign.id == post.assignment_id)
    |> join(:inner, [post, assign], sa in StudentAssignment, sa.assignment_id == assign.id)
    |> join(:inner, [post, assign, sa], sc in StudentClass, sc.id == sa.student_class_id)
    |> join(:inner, [post, assign, sa, sc], class in Class, class.id == assign.class_id)
    |> where([post, assign, sa], sa.is_post_notifications == true)
    |> where([post, assign, sa, sc], sc.is_dropped == false and sc.student_id == ^student_id)
    |> where([post], post.student_id != ^student_id)
    |> select([post, assign, sa, sc, class], %{post: post, assignment: assign, class: class, student_assignment: sa})
    |> Repo.all()
  end

  def get_assignment_reminder(num, topic) do
    messages = get_messages(topic, num)

    case messages |> get_random_message() do
      nil -> get_default(topic, num)
      message -> message
    end 
  end

  def add_assignment_message(%{"reminder_message" => params}) do
    ReminderNotification.changeset(%ReminderNotification{}, params)
    |> Repo.insert()
  end

  def get_assignment_messages() do
    Repo.all(ReminderNotification)
  end

  def delete_assignment_messages(id) do
    Repo.get!(ReminderNotification, id)
    |> Repo.delete()
  end

  def get_assignment_message_topics() do
    Repo.all(Topic)
  end

  def get_assignment_message_topic_by_id!(id) do
    Repo.get!(Topic, id)
  end

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

  defp get_default(@today_topic, num) when num > 1, do: @default_message_today_mult
  defp get_default(@today_topic, _num), do: @default_message_today_single
  defp get_default(@tomorrow_topic, num) when num > 1, do: @default_message_tomorrow_mult
  defp get_default(@tomorrow_topic, _num), do: @default_message_tomorrow_single
  defp get_default(@future_topic, num) when num > 1, do: @default_message_future_mult
  defp get_default(@future_topic, _num), do: @default_message_future_single

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