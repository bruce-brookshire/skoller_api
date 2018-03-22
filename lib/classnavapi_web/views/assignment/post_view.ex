defmodule ClassnavapiWeb.Assignment.PostView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Assignment.PostView
  alias Classnavapi.Repo

  def render("show.json", %{post: post}) do
    render_one(post, PostView, "post.json")
  end

  def render("post.json", %{post: post}) do
    post = post |> Repo.preload([:student])
    %{
      post: post.post,
      student: render_one(post.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: post.id,
      inserted_at: post.inserted_at
    }
  end

  def render("post-detail.json", %{post: %{post: post, assignment: assign, class: class}}) do
    post = post |> Repo.preload([:student])
    %{
      post: post.post,
      student: render_one(post.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: post.id,
      inserted_at: post.inserted_at,
      assignment: render_one(assign, ClassnavapiWeb.AssignmentView, "assignment-short.json"),
      class: render_one(class, ClassnavapiWeb.ClassView, "class_short.json")
    }
  end
end