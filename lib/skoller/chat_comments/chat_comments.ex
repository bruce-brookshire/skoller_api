defmodule Skoller.ChatComments do
  @moduledoc """
  The context module for chat comments
  """

  alias Skoller.Repo
  alias Skoller.ChatComments.Comment
  alias Skoller.ChatComments.Star
  alias Skoller.ChatComments.Notifications
  alias Skoller.ChatPosts

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
    |> Ecto.Multi.run(:star, &insert_star(&1.comment, student_id))
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

  defp insert_star(comment, student_id) do
    %Star{}
    |> Star.changeset(%{chat_comment_id: comment.id, student_id: student_id})
    |> Repo.insert()
  end
end