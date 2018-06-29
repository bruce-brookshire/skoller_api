defmodule Skoller.ChatPosts do
  @moduledoc """
  The context module for chat posts
  """

  alias Skoller.Repo
  alias Skoller.Chat.Post

  @doc """
  Gets a chat post by id

  ## Returns
  `%Skoller.Chat.Post{}` or `Ecto.NoResultsError`
  """
  def get!(post_id) do
    Repo.get!(Post, post_id)
  end

  @doc """
  Gets a chat post by student id and chat post id.

  ## Returns
  `%Skoller.Chat.Post{}` or `Ecto.NoResultsError`
  """
  def get_post_by_student_and_id!(student_id, post_id) do
    Repo.get_by!(Post, student_id: student_id, id: post_id)
  end

  @doc """
  Deletes a chat post

  ## Returns
  `{:ok, %Skoller.Chat.Post{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def delete(%Post{} = post) do
    Repo.delete(post)
  end
end