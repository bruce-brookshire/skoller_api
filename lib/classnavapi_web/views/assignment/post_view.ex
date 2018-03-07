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
end