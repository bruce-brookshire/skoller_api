defmodule Skoller.Assignments do
  @moduledoc """
  Context module for assignments
  """

  alias Skoller.Repo
  alias Skoller.Assignments.ReminderNotification
  alias Skoller.Assignments.ReminderNotification.Topic
  alias Skoller.AssignmentPosts.Post
  alias Skoller.Assignments.Assignment
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Classes.Class
  alias Skoller.StudentAssignments
  alias Skoller.Classes.Weights
  alias Skoller.EnrolledStudents

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
  Gets an assignment by id.

  ## Returns
  `Skoller.Assignments.Assignment` or `Ecto.NoResultsError`
  """
  def get_assignment_by_id!(assignment_id) do
    Repo.get!(Assignment, assignment_id)
  end

  @doc """
  Gets an assignment by id.

  ## Returns
  `Skoller.Assignments.Assignment` or `nil`
  """
  def get_assignment_by_id(assignment_id) do
    Repo.get(Assignment, assignment_id)
  end

  @doc """
    Creates an assignment for a class.

    Returns the student assignments created due to the new assignment.

    ## Returns
    `%{assignment: Skoller.Assignments.Assignment, student_assignments: [Skoller.StudentAssignments.StudentAssignment]}`
  """
  def create_assignment(class_id, user_id, params) do
    params = params
    |> Map.put_new("weight_id", nil)
    changeset = %Assignment{}
      |> Assignment.changeset(params)
      |> check_weight_id(params)
      |> validate_class_weight(class_id)
      |> Ecto.Changeset.change(%{created_by: user_id, updated_by: user_id, created_on: params["created_on"]})

    Ecto.Multi.new
    |> Ecto.Multi.insert(:assignment, changeset)
    |> Ecto.Multi.run(:student_assignments, &StudentAssignments.insert_assignments(&1))
    |> Repo.transaction()
  end

  @doc """
    Updates an assignment for a class.

    Returns the student assignments created due to the updated assignment.

    ## Returns
    `%{assignment: Skoller.Assignments.Assignment, student_assignments: [Skoller.StudentAssignments.StudentAssignment]}`
  """
  def update_assignment(id, user_id, params) do
    params = params |> Map.put_new("weight_id", nil)
    assign_old = get_assignment_by_id!(id)
    changeset = assign_old
      |> Assignment.changeset(params)
      |> check_weight_id(params)
      |> validate_class_weight(assign_old.class_id)
      |> Ecto.Changeset.change(%{updated_by: user_id})

    Ecto.Multi.new
    |> Ecto.Multi.update(:assignment, changeset)
    |> Ecto.Multi.run(:student_assignments, &StudentAssignments.update_assignments(&1))
    |> Repo.transaction()
  end

  @doc """
  Deletes an assignment by id.

  ## Returns
  `{:ok, assignment}` or `{:error, changeset}`
  """
  def delete_assignment(id) do
    id
    |> get_assignment_by_id!()
    |> Repo.delete()
  end

  @doc """
  Gets all assignment posts for a student.

  ## Notes
  The student's own posts are excluded.

  ## Returns
  `[%{post: Skoller.AssignmentPosts.Post, assignment: Skoller.Assignments.Assignment, class: Skoller.Classes.Class, student_assignment: Skoller.StudentAssignments.StudentAssignment}]`
  or `[]`
  """
  def get_assignment_post_notifications(student_id) do
    from(post in Post)
    |> join(:inner, [post], assign in Assignment, assign.id == post.assignment_id)
    |> join(:inner, [post, assign], sa in StudentAssignment, sa.assignment_id == assign.id)
    |> join(:inner, [post, assign, sa], sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)), sc.id == sa.student_class_id)
    |> join(:inner, [post, assign, sa, sc], class in Class, class.id == assign.class_id)
    |> where([post, assign, sa], sa.is_post_notifications == true)
    |> where([post], post.student_id != ^student_id)
    |> select([post, assign, sa, sc, class], %{post: post, assignment: assign, class: class, student_assignment: sa})
    |> Repo.all()
  end

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

  defp check_weight_id(changeset, %{"weight_id" => nil}) do
    changeset |> Ecto.Changeset.force_change(:weight_id, nil)
  end
  defp check_weight_id(changeset, _params), do: changeset

  defp validate_class_weight(%Ecto.Changeset{changes: %{weight_id: nil}} = changeset, class_id) do
    weights = Weights.get_class_weights(class_id)

    case weights do
      [] -> changeset
      _ -> changeset |> Ecto.Changeset.add_error(:weight_id, "Weight can't be null when weights exist.")
    end
  end
  defp validate_class_weight(%Ecto.Changeset{changes: %{class_id: class_id, weight_id: weight_id}, valid?: true} = changeset, _class_id) do
    case Weights.get_class_weight_by_ids(class_id, weight_id) do
      nil -> changeset |> Ecto.Changeset.add_error(:weight_id, "Weight class combination invalid")
      _ -> changeset
    end
  end
  defp validate_class_weight(changeset, _class_id), do: changeset
end