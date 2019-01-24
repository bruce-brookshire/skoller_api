defmodule Skoller.Users.Students do
  @moduledoc """
  A context module for users and students
  """

  alias Skoller.Repo
  alias Skoller.Users.User

  import Ecto.Query
  
  @doc """
  Gets a user by student id.

  ## Returns
  `Skoller.Users.User` or `nil`
  """
  def get_user_by_student_id(student_id) do
    Repo.get_by(User, student_id: student_id)
  end

  @doc """
  Gets student users.

  ## Preloads
  `:student` relationship

  ## Returns
  `[Skoller.Users.User]` or `[]`
  """
  def get_student_users() do
    from(u in User)
    |> where([u], not(is_nil(u.student_id)))
    |> preload([s], [:student])
    |> Repo.all()
  end
end
