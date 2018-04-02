defmodule Classnavapi.Assignments do

  alias Classnavapi.Repo
  alias Classnavapi.Assignment.Post
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class

  import Ecto.Query

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