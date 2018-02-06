defmodule ClassnavapiWeb.Class.ChatPostView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.ChatPostView
  alias ClassnavapiWeb.Class.ChatCommentView
  alias ClassnavapiWeb.Class.Chat.LikeView
  alias ClassnavapiWeb.Helpers.ChatHelper

  def render("index.json", %{chat_posts: chat_posts}) do
    render_many(chat_posts, ChatPostView, "chat_post.json")
  end

  def render("show.json", %{chat_post: chat_post}) do
    render_one(chat_post, ChatPostView, "chat_post_detail.json")
  end

  def render("chat_post.json", %{chat_post: chat_post}) do
    chat_post = chat_post |> Repo.preload([:student, :chat_comments, :likes])
    %{
      post: chat_post.post,
      student: render_one(chat_post.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: chat_post.id,
      comments: render_many(chat_post.chat_comments, ChatCommentView, "chat_comment.json"),
      likes: render_many(chat_post.likes, LikeView, "like.json")
    }
  end

  def render("chat_post_detail.json", %{chat_post: %{chat_post: chat_post, current_student_id: student_id}}) do
    chat_post = chat_post |> Repo.preload([:student, :chat_comments, :likes])
    %{
      post: chat_post.post,
      student: render_one(chat_post.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: chat_post.id,
      comments: render_many(chat_post.chat_comments, ChatCommentView, "chat_comment_detail.json", %{current_student_id: student_id}),
      likes: render_many(chat_post.likes, LikeView, "like.json"),
      is_liked: chat_post.likes |> ChatHelper.is_liked(student_id)
    }
  end

  def render("chat_post_detail.json", %{chat_post: chat_post}) do
    chat_post = chat_post |> Repo.preload([:student, :chat_comments, :likes])
    %{
      post: chat_post.post,
      student: render_one(chat_post.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: chat_post.id,
      comments: render_many(chat_post.chat_comments, ChatCommentView, "chat_comment_detail.json"),
      likes: render_many(chat_post.likes, LikeView, "like.json")
    }
  end
end
