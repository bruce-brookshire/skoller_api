defmodule Skoller.ChatComments do
  @moduledoc """
  The context module for chat comments
  """

  alias Skoller.Repo
  alias Skoller.ChatComments.Comment
  alias Skoller.ChatComments.Star
  alias Skoller.ChatComments.Like
  alias Skoller.ChatComments.Notifications
  alias Skoller.ChatPosts

  import Ecto.Query

  @doc """
  Gets a comment by id

  ## Returns
  `%Skoller.ChatComments.Comment{}` or `Ecto.NoResultsError`
  """
  def get!(comment_id) do
    Repo.get!(Comment, comment_id)
  end

  @doc """
  Gets a comment by student id and chat post id.

  ## Returns
  `%Skoller.ChatComments.Comment{}` or `Ecto.NoResultsError`
  """
  def get_comment_by_student_and_id!(student_id, comment_id) do
    Repo.get_by!(Comment, student_id: student_id, id: comment_id)
  end

  @doc """
  Deletes a comment.

  ## Returns
  `{:ok, %Skoller.ChatComments.Comment{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def delete(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Creates a chat comment.

  On comment creation, the comment will be starred for the creator, and all other students
  will see the post as unread. A notification will also be sent.

  ## Returns
  `{:ok, comment}` or `{:error, changeset}`
  """
  def create(attrs, student_id) do
    changeset = Comment.changeset(%Comment{}, attrs)

    result = Ecto.Multi.new
    |> Ecto.Multi.insert(:comment, changeset)
    |> Ecto.Multi.run(:star, &insert_star(&1.comment.id, student_id))
    |> Ecto.Multi.run(:unread, &ChatPosts.unread_posts(&1.comment.chat_post_id, student_id))
    |> Repo.transaction()

    case result do
      {:ok, %{comment: comment}} -> 
        Task.start(Notifications, :send_new_comment_notification, [comment, student_id])
        {:ok, comment}
      {:error, _, field, _} ->
        {:error, field}
    end
  end

  @doc """
  Updates a comment

  ## Returns
  `{:ok, comment}` or `{:error, changeset}`
  """
  def update(comment_old, attrs) do
    Comment.changeset_update(comment_old, attrs)
    |> Repo.update()
  end

  @doc """
  Unreads comments for all other `student_id` in the class.
  """
  def unread_comments(chat_comment_id, student_id) do
    items = from(s in Star)
    |> where([s], s.is_read == true and s.student_id != ^student_id)
    |> where([s], s.chat_comment_id == ^chat_comment_id)
    |> Repo.update_all(set: [is_read: false, updated_at: DateTime.utc_now])
    {:ok, items}
  end

  @doc """
  Likes a comment.

  ## Returns
  `{:ok, comment}` or `{:error, changeset}`
  """
  def like_comment(attrs) do
    result = Like.changeset(%Like{}, attrs)
    |> Repo.insert()

    case result do
      {:ok, like} ->
        {:ok, get!(like.chat_comment_id)}
      result -> result
    end
  end

  @doc """
  Unlike a comment.

  ## Returns
  `{:ok, comment}` or `{:error, changeset}`
  """
  def unlike_comment(comment_id, student_id) do
    result = get_like_by_student_and_id!(student_id, comment_id)
    |> Repo.delete()

    case result do
      {:ok, _like} ->
        {:ok, get!(comment_id)}
      result -> result
    end
  end

  @doc """
  Stars a comment.

  ## Returns
  `{:ok, comment}` or `{:error, changeset}`
  """
  def star_comment(comment_id, student_id) do
    case insert_star(comment_id, student_id) do
      {:ok, _star} ->
        {:ok, get!(comment_id)}
      result -> result
    end
  end

  @doc """
  Unstars a comment.

  ## Returns
  `{:ok, comment}` or `{:error, changeset}`
  """
  def unstar_comment(comment_id, student_id) do
    result = get_star_by_student_and_id!(student_id, comment_id)
    |> Repo.delete()

    case result do
      {:ok, _star} ->
        {:ok, get!(comment_id)}
      result -> result
    end
  end

  @doc """
  Gets all comment stars on comments by `post_id` and `student_id`
  """
  def get_student_comment_stars_by_post(post_id, student_id) do
    from(cs in Star)
    |> join(:inner, [cs], c in Comment, cs.chat_comment_id == c.id)
    |> where([cs], cs.is_read == false and cs.student_id == ^student_id)
    |> where([cs, c], c.chat_post_id == ^post_id)
    |> Repo.all()
  end

  defp get_like_by_student_and_id!(student_id, comment_id) do
    Repo.get_by!(Like, student_id: student_id, chat_comment_id: comment_id)
  end

  defp get_star_by_student_and_id!(student_id, comment_id) do
    Repo.get_by!(Star, student_id: student_id, chat_comment_id: comment_id)
  end

  defp insert_star(comment_id, student_id) do
    %Star{}
    |> Star.changeset(%{chat_comment_id: comment_id, student_id: student_id})
    |> Repo.insert()
  end
end