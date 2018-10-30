defmodule Skoller.ChatReplies do
  @moduledoc """
  The context module for chat replys
  """

  alias Skoller.Repo
  alias Skoller.ChatReplies.Reply
  alias Skoller.ChatReplies.Notifications
  alias Skoller.ChatComments
  alias Skoller.ChatPosts

  @doc """
  Gets a reply by id

  ## Returns
  `%Skoller.ChatReplies.Reply{}` or `Ecto.NoResultsError`
  """
  def get!(reply_id) do
    Repo.get!(Reply, reply_id)
  end

  @doc """
  Gets a reply by student id and chat post id.

  ## Returns
  `%Skoller.ChatReplies.Reply{}` or `Ecto.NoResultsError`
  """
  def get_reply_by_student_and_id!(student_id, reply_id) do
    Repo.get_by!(Reply, student_id: student_id, id: reply_id)
  end

  @doc """
  Deletes a reply.

  ## Returns
  `{:ok, %Skoller.ChatReplies.Reply{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def delete(%Reply{} = reply) do
    Repo.delete(reply)
  end

  @doc """
  Creates a chat reply.

  Unreads all posts and comments that are starred for students other than `student_id`

  Will send a notification to students who have this starred.

  ## Returns
  `{:ok, reply}` or `{:error, changeset}`
  """
  def create(attrs, student_id) do
    changeset = Reply.changeset(%Reply{}, attrs)

    result = Ecto.Multi.new
    |> Ecto.Multi.insert(:reply, changeset)
    |> Ecto.Multi.run(:unread_post, &unread_post(&1.reply, student_id))
    |> Ecto.Multi.run(:unread_comments, &ChatComments.unread_comments(&1.reply.chat_comment_id, student_id))
    |> Repo.transaction()

    case result do
      {:ok, %{reply: reply}} -> 
        Task.start(Notifications, :send_new_reply_notification, [reply, student_id])
        {:ok, reply}
      {:error, _, field, _} ->
        {:error, field}
    end
  end

  @doc """
  Updates a reply.

  ## Returns
  `{:ok, reply}` or `{:error, changeset}`
  """
  def update(reply_old, attrs) do
    Reply.changeset_update(reply_old, attrs)
    |> Repo.update()
  end

  defp unread_post(reply, student_id) do
    comment = ChatComments.get!(reply.chat_comment_id)
    
    ChatPosts.unread_posts(comment.chat_post_id, student_id)
  end
end