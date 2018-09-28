defmodule Skoller.StudentClasses.Users do
  @moduledoc """
  A context module for users in a class
  """

  alias Skoller.Repo
  alias Skoller.Students
  alias Skoller.Users.User

  import Ecto.Query

  @doc """
  Gets the users enrolled in a class.
  
  ## Returns
  `[Skoller.Users.User]` or `[]`
  """
  def get_users_in_class(class_id) do
    from(u in User)
    |> join(:inner, [u], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.student_id == u.student_id)
    |> where([u, sc], sc.class_id == ^class_id)
    |> Repo.all()
  end
end