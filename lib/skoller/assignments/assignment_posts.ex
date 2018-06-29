defmodule Skoller.AssignmentPosts do
  @moduledoc """
  The context module for assignment posts
  """

  alias Skoller.Repo
  alias Skoller.Assignment.Post

  @doc """
  Gets an assignment post by id

  ## Returns
  `%Skoller.Assignment.Post{}` or `Ecto.NoResultsError`
  """
  def get!(post_id) do
    Repo.get!(Post, post_id)
  end

  @doc """
  Gets an assignment post by student id and chat post id.

  ## Returns
  `%Skoller.Assignment.Post{}` or `Ecto.NoResultsError`
  """
  def get_post_by_student_and_id!(student_id, post_id) do
    Repo.get_by!(Post, student_id: student_id, id: post_id)
  end

  @doc """
  Deletes an assignment post

  ## Returns
  `{:ok, %Skoller.Assignment.Post{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def delete(%Post{} = post) do
    Repo.delete(post)
  end
end