defmodule Skoller.ChatPosts do
  @moduledoc """
  The context module for chat posts
  """

  alias Skoller.Repo
  alias Skoller.ChatPosts.Post
  alias Skoller.ChatPosts.Star

  import Ecto.Query

  @doc """
  Gets a post by id

  ## Returns
  `%Skoller.ChatPosts.Post{}` or `Ecto.NoResultsError`
  """
  def get!(post_id) do
    Repo.get!(Post, post_id)
  end

  @doc """
  Gets a post by student id and chat post id.

  ## Returns
  `%Skoller.ChatPosts.Post{}` or `Ecto.NoResultsError`
  """
  def get_post_by_student_and_id!(student_id, post_id) do
    Repo.get_by!(Post, student_id: student_id, id: post_id)
  end

  @doc """
  Deletes a post.

  ## Returns
  `{:ok, %Skoller.ChatPosts.Post{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def delete(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Gets all chat posts in a class.

  ## Returns
  `[Skoller.ChatPosts.Post]` or `[]`
  """
  def get_posts_by_class(class_id) do
    from(p in Post)
    |> where([p], p.class_id == ^class_id)
    |> Repo.all()
  end

  @doc """
  Creates a chat post

  ## Returns
  `{:ok, post}` or `{:error, changeset}`
  """
  def create(attrs) do
    Post.changeset(%Post{}, attrs)
    |> Repo.insert()
  end

  @doc """
  Unreads posts for all other `student_id` in the class.

  ## Returns
  `{:ok, Repo.update_all result}`
  """
  def unread_posts(chat_post_id, student_id) do
    items = from(s in Star)
    |> where([s], s.id == ^chat_post_id and s.is_read == true and s.student_id != ^student_id)
    |> Repo.update_all(set: [is_read: false, updated_at: DateTime.utc_now])
    {:ok, items}
  end
end