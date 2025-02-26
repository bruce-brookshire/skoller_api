defmodule Skoller.AssignmentPosts do
  @moduledoc """
  The context module for assignment posts
  """

  alias Skoller.Repo
  alias Skoller.AssignmentPosts.Post
  alias Skoller.Assignments.Assignment
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.EnrolledStudents
  alias Skoller.Classes.Class
  alias Skoller.AssignmentPosts.StudentAssignments
  alias Skoller.AssignmentPosts.Notifications

  import Ecto.Query

  @doc """
  Gets an assignment post by id

  ## Returns
  `%Skoller.AssignmentPosts.Post{}` or `Ecto.NoResultsError`
  """
  def get_assignment_post!(post_id) do
    Repo.get!(Post, post_id)
  end

  @doc """
  Gets an assignment post by student id and chat post id.

  ## Returns
  `%Skoller.AssignmentPosts.Post{}` or `Ecto.NoResultsError`
  """
  def get_post_by_student_and_id!(student_id, post_id) do
    Repo.get_by!(Post, student_id: student_id, id: post_id)
  end

  @doc """
  Deletes an assignment post

  ## Returns
  `{:ok, %Skoller.AssignmentPosts.Post{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def delete_assignment_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Creates an assignment post and unreads the assignment for all other students.

  ## Returns
  `{:ok, %{post: post, student_assignment: [{:ok, StudentAssignment}]}}` or an ecto multi error.
  """
  def create_assignment_post(attrs) do
    changeset = Post.changeset(%Post{}, attrs)

    result = Ecto.Multi.new()
    |> Ecto.Multi.insert(:post, changeset)
    |> Ecto.Multi.run(:student_assignment, fn (_, changes) -> StudentAssignments.un_read_assignment(changes.post.student_id, changes.post.assignment_id) end)
    |> Repo.transaction()

    case result do
      {:ok, %{post: post}} ->
        Task.start(Notifications, :send_assignment_post_notification, [post, post.student_id])
        {:ok, post}
      {:error, _, failed_value, _} ->
        {:error, failed_value}
    end
  end

  @doc """
  Updates an assignment post.

  ## Returns
  `{:ok, post}` or `{:error, changeset}`
  """
  def update_assignment_post(post_old, attrs) do
    Post.changeset_update(post_old, attrs)
    |> Repo.update()
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
    |> join(:inner, [post], assign in Assignment, on: assign.id == post.assignment_id)
    |> join(:inner, [post, assign], sa in StudentAssignment, on: sa.assignment_id == assign.id)
    |> join(:inner, [post, assign, sa], sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)), on: sc.id == sa.student_class_id)
    |> join(:inner, [post, assign, sa, sc], class in Class, on: class.id == assign.class_id)
    |> where([post, assign, sa], sa.is_post_notifications == true)
    |> where([post], post.student_id != ^student_id)
    |> select([post, assign, sa, sc, class], %{post: post, assignment: assign, class: class, student_assignment: sa})
    |> Repo.all()
  end
end