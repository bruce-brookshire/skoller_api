defmodule Skoller.ChatComments do
  @moduledoc """
  The context module for chat comments
  """

  alias Skoller.Repo
  alias Skoller.Chat.Comment

  @doc """
  Gets a comment by id

  ## Returns
  `%Skoller.Chat.Comment{}` or `Ecto.NoResultsError`
  """
  def get!(comment_id) do
    Repo.get!(Comment, comment_id)
  end

  @doc """
  Gets a comment by student id and chat post id.

  ## Returns
  `%Skoller.Chat.Comment{}` or `Ecto.NoResultsError`
  """
  def get_comment_by_student_and_id!(student_id, comment_id) do
    Repo.get_by!(Comment, student_id: student_id, id: comment_id)
  end

  @doc """
  Deletes a comment.

  ## Returns
  `{:ok, %Skoller.Chat.Comment{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def delete(%Comment{} = comment) do
    Repo.delete(comment)
  end
end