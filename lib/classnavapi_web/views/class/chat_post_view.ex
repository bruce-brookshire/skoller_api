defmodule ClassnavapiWeb.Class.ChatPostView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.ChatPostView
  alias ClassnavapiWeb.Class.ChatCommentView
  alias ClassnavapiWeb.Class.Chat.LikeView
  alias ClassnavapiWeb.Helpers.ChatHelper
  alias Classnavapi.Chat.Post.Star

  def render("index.json", %{chat_posts: %{chat_posts: chat_posts, color: color}, current_student_id: current_student_id}) do
    render_many(chat_posts, ChatPostView, "chat_post.json", %{current_student_id: current_student_id, color: color})
  end

  def render("index.json", %{chat_posts: chat_posts, current_student_id: current_student_id}) do
    render_many(chat_posts, ChatPostView, "chat_post.json", %{current_student_id: current_student_id})
  end

  def render("index.json", %{chat_posts: chat_posts}) do
    render_many(chat_posts, ChatPostView, "chat_post.json")
  end

  def render("show.json", %{chat_post: chat_post, current_student_id: current_student_id}) do
    render_one(chat_post, ChatPostView, "chat_post_detail.json", %{current_student_id: current_student_id})
  end

  def render("show.json", %{chat_post: chat_post}) do
    render_one(chat_post, ChatPostView, "chat_post_detail.json")
  end

  def render("chat_post.json", %{chat_post: chat_post, current_student_id: student_id, color: color}) do
    student_chat_post(chat_post, color, student_id)
  end

  def render("chat_post.json", %{chat_post: %{chat_post: chat_post, color: color}, current_student_id: student_id}) do
    student_chat_post(chat_post, color, student_id)
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

  def render("chat_post_detail.json", %{chat_post: %{chat_post: chat_post, color: color}, current_student_id: student_id}) do
    chat_post = chat_post |> Repo.preload([:student, :chat_comments, :likes, :class])
    %{
      post: chat_post.post,
      student: render_one(chat_post.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: chat_post.id,
      comments: render_many(chat_post.chat_comments, ChatCommentView, "chat_comment_detail.json", %{current_student_id: student_id}),
      likes: render_many(chat_post.likes, LikeView, "like.json"),
      is_liked: chat_post.likes |> ChatHelper.is_liked(student_id),
      is_starred: chat_post |> is_starred(student_id),
      class: render_one(chat_post.class, ClassnavapiWeb.ClassView, "class_short.json"),
      color: color
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

  defp student_chat_post(chat_post, color, student_id) do
    chat_post = chat_post |> Repo.preload([:student, :chat_comments, :likes, :class])
    %{
      post: chat_post.post,
      student: render_one(chat_post.student, ClassnavapiWeb.StudentView, "student-short.json"),
      id: chat_post.id,
      comments: render_many(chat_post.chat_comments, ChatCommentView, "chat_comment.json"),
      likes: render_many(chat_post.likes, LikeView, "like.json"),
      is_liked: chat_post.likes |> ChatHelper.is_liked(student_id),
      is_starred: chat_post |> is_starred(student_id),
      class: render_one(chat_post.class, ClassnavapiWeb.ClassView, "class_short.json"),
      color: color
    }
  end

  defp is_starred(post, student_id) do
    case Repo.get_by(Star, chat_post_id: post.id, student_id: student_id) do
      nil -> false
      _ -> true
    end
  end
end
