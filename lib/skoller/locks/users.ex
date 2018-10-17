defmodule Skoller.Locks.Users do
  @moduledoc """
  A context module for lock users
  """

  alias Skoller.Locks.Lock
  alias Skoller.Users.User
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Gets the locks by class.

  ## Returns
  `[%{lock: Skoller.Locks.Lock, user: Skoller.Users.User}]` or `[]`
  """
  def get_user_locks_by_class(class_id) do
    from(l in Lock)
    |> join(:inner, [l], u in User, l.user_id == u.id)
    |> where([l], l.class_id == ^class_id)
    |> select([l, u], %{lock: l, user: u})
    |> Repo.all()
  end

  @doc """
    Gets a user's locks. If no type is passed, it will return all locks for a user.
  """
  def get_user_lock(user, nil) do
    from(lock in Lock)
    |> where([lock], lock.user_id == ^user.id)
    |> Repo.all()
  end
  def get_user_lock(user, type) do
    from(lock in Lock)
    |> where([lock], lock.user_id == ^user.id)
    |> where([lock], lock.class_lock_section_id == ^type)
    |> Repo.all()
  end

  @doc """
  Gets locks by class and user.

  ## Returns
  `[Skoller.Locks.Lock]` or `[]`
  """
  def get_locks_by_class_and_user(class_id, user_id) do
    from(l in Lock)
    |> where([l], l.class_id == ^class_id and l.user_id == ^user_id)
    |> Repo.all()
  end
end