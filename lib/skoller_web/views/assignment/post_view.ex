defmodule SkollerWeb.Assignment.PostView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Assignment.PostView
  alias Skoller.Repo

  def render("show.json", %{post: post}) do
    render_one(post, PostView, "post.json")
  end

  def render("post.json", %{post: post}) do
    post = post |> Repo.preload([:student])
    %{
      post: post.post,
      student: render_one(post.student, SkollerWeb.StudentView, "student-short.json"),
      id: post.id,
      inserted_at: post.inserted_at
    }
  end

  def render("post-detail.json", %{post: %{post: post, assignment: assign, class: class, student_assignment: student_assignment}}) do
    post = post |> Repo.preload([:student])
    %{
      post: post.post,
      student: render_one(post.student, SkollerWeb.StudentView, "student-short.json"),
      id: post.id,
      inserted_at: post.inserted_at,
      student_assignment_id: student_assignment.id,
      is_read: student_assignment.is_read,
      assignment: render_one(assign, SkollerWeb.AssignmentView, "assignment-short.json"),
      class: render_one(class, SkollerWeb.ClassView, "class_short.json")
    }
  end
end