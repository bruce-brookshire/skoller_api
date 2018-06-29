defmodule Skoller.ChatReplies do
  @moduledoc """
  The context module for chat replys
  """

  alias Skoller.Repo
  alias Skoller.Chat.Reply

  @doc """
  Gets a reply by id

  ## Returns
  `%Skoller.Chat.Reply{}` or `Ecto.NoResultsError`
  """
  def get!(reply_id) do
    Repo.get!(Reply, reply_id)
  end

  @doc """
  Gets a reply by student id and chat post id.

  ## Returns
  `%Skoller.Chat.Reply{}` or `Ecto.NoResultsError`
  """
  def get_reply_by_student_and_id!(student_id, reply_id) do
    Repo.get_by!(Reply, student_id: student_id, id: reply_id)
  end

  @doc """
  Deletes a reply.

  ## Returns
  `{:ok, %Skoller.Chat.Reply{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def delete(%Reply{} = reply) do
    Repo.delete(reply)
  end
end