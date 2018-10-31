defmodule Skoller.ChatPosts do
  @moduledoc """
  The context module for chat posts
  """

  alias Skoller.Repo
  alias Skoller.ChatPosts.Post
  alias Skoller.ChatPosts.Star
  alias Skoller.ChatPosts.Like
  alias Skoller.ChatPosts.Notifications

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
  Creates a chat post.

  Will star the post for the creator, and send notifications to members in the class with notifications enabled.

  ## Returns
  `{:ok, post}` or `{:error, changeset}`
  """
  def create(attrs, student_id) do
    changeset = Post.changeset(%Post{}, attrs)

    results = Ecto.Multi.new
    |> Ecto.Multi.insert(:post, changeset)
    |> Ecto.Multi.run(:star, &insert_star(&1.post.id, student_id))
    |> Repo.transaction()

    case results do
      {:ok, %{post: post}} ->
        Task.start(Notifications, :send_new_post_notification, [post, student_id])
        {:ok, post}
      {:error, _, field, _} ->
        {:error, field}
    end
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

  @doc """
  Updates a chat post.

  ## Returns
  `{:ok, post}` or `{:error, changeset}`
  """
  def update(post_old, attrs) do
    Post.changeset_update(post_old, attrs)
    |> Repo.update()
  end

  @doc """
  Likes a chat post.

  ## Returns
  `{:ok, post}` or `{:error, changeset}`
  """
  def like_post(attrs) do
    result = Like.changeset(%Like{}, attrs)
    |> Repo.insert()

    case result do
      {:ok, like} -> 
        {:ok, get!(like.chat_post_id)}
      result ->
        result
    end
  end

  @doc """
  Unlikes a chat post.

  ## Returns
  `{:ok, post}` or `{:error, changeset}`
  """
  def unlike_post(post_id, student_id) do
    result = get_like_by_student_and_id!(student_id, post_id)
    |> Repo.delete()

    case result do
      {:ok, _struct} ->
        {:ok, get!(post_id)}
      result ->
        result
    end
  end

  @doc """
  Stars a chat post.

  ## Returns
  `{:ok, post}` or `{:error, changeset}`
  """
  def star_post(post_id, student_id) do
    case insert_star(post_id, student_id) do
      {:ok, _star} -> 
        {:ok, get!(post_id)}
      result ->
        result
    end
  end

  @doc """
  Unstars a chat post.

  ## Returns
  `{:ok, post}` or `{:error, changeset}`
  """
  def unstar_post(post_id, student_id) do
    result = get_star_by_student_and_id!(student_id, post_id)
    |> Repo.delete()

    case result do
      {:ok, _star} -> 
        {:ok, get!(post_id)}
      result ->
        result
    end
  end

  @doc """
  Gets a post star by student and post id.
  """
  def get_star_by_student_and_id(student_id, post_id) do
    Repo.get_by(Star, student_id: student_id, chat_post_id: post_id)
  end

  defp get_star_by_student_and_id!(student_id, post_id) do
    Repo.get_by!(Star, student_id: student_id, chat_post_id: post_id)
  end

  defp get_like_by_student_and_id!(student_id, post_id) do
    Repo.get_by!(Like, student_id: student_id, chat_post_id: post_id)
  end

  defp insert_star(post_id, student_id) do
    %Star{}
    |> Star.changeset(%{chat_post_id: post_id, student_id: student_id})
    |> Repo.insert()
  end
end