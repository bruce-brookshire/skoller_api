defmodule Classnavapi.Assignments do

  alias Classnavapi.Repo
  alias Classnavapi.Assignment.Post
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class
  alias Classnavapi.Assignments.ReminderNotification

  import Ecto.Query

  @today_topic "Assignment.Reminder.Today"
  @future_topic "Assignment.Reminder.Future"

  @default_message_today_single "You have 1 assignment due today. Check it out!"
  @default_message_today_mult "You have [num] assignments due today. Check them out!"
  @default_message_future_single "You have 1 assignment coming up. Check it out!"
  @default_message_future_mult "You have [num] assignments coming up. Check them out!"

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

  def get_assignment_reminder(num, @today_topic) do
    get_assignment_reminder(num, @today_topic, :today)
  end
  def get_assignment_reminder(num, @future_topic) do
    get_assignment_reminder(num, @future_topic, :future)
  end

  defp get_assignment_reminder(num, topic, atom) do
    assignments = get_messages(topic, num)

    case assignments |> get_random_message(num) do
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

  defp get_random_message([], _num), do: nil
  defp get_random_message(assignments, num) do
    
  end
end