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

  import Ecto.Query

  @doc """
  Gets an assignment post by id

  ## Returns
  `%Skoller.AssignmentPosts.Post{}` or `Ecto.NoResultsError`
  """
  def get!(post_id) do
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
  def delete(%Post{} = post) do
    Repo.delete(post)
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
end