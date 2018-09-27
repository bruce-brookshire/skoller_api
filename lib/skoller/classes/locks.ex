defmodule Skoller.Classes.Locks do
  @moduledoc """
  A context module for class locks
  """

  alias Skoller.Classes.Class
  alias Skoller.Repo
  alias Skoller.Locks.Lock
  alias Skoller.Classes.Schools
  alias Skoller.Users.User
  alias Skoller.UserRole

  import Ecto.Query

  @student_role 100

  @diy_complete_lock 200

  @doc """
  Gets a count of classes completed by students created between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  
  """
  def classes_completed_by_diy_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> join(:inner, [c, cs], l in Lock, l.class_id == c.id and l.class_lock_section_id == @diy_complete_lock and l.is_completed == true)
    |> join(:inner, [c, cs, l], u in User, u.id == l.user_id)
    |> join(:inner, [c, cs, l, u], r in UserRole, r.user_id == u.id)
    |> where([c, cs, l, u, r], r.role_id == @student_role)
    |> where([c], fragment("?::date", c.inserted_at) >= ^date_start and fragment("?::date", c.inserted_at) <= ^date_end)
    |> Repo.aggregate(:count, :id)
  end
end