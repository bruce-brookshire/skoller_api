defmodule Classnavapi.Assignments do

  alias Classnavapi.Repo
  alias Classnavapi.Assignments.ReminderNotification
  alias Classnavapi.Assignment.Post
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class

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

  def delete_assignment_messages(id) do
    Repo.get!(ReminderNotification, id)
    |> Repo.delete()
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
end