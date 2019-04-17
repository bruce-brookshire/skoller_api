defmodule Skoller.Analytics.DIY do
  @moduledoc """
  A context module for diy analytics
  """

  alias Skoller.Classes.Class
  alias Skoller.Repo
  alias Skoller.Classes.Schools
  alias Skoller.Users.User
  alias Skoller.UserRoles.UserRole
  alias Skoller.Assignments.Assignment

  import Ecto.Query

  @student_role 100

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
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)), on: c.id == cs.class_id)
    |> join(:inner, [c, cs], cu in subquery(classes_with_student_assignment_entry_subquery()), on: c.id == cu.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^date_start and fragment("?::date", c.inserted_at) <= ^date_end)
    |> distinct([c], c.id)
    |> Repo.aggregate(:count, :id)
  end

  defp classes_with_student_assignment_entry_subquery() do
    from(a in Assignment)
    |> join(:inner, [a], u in User, on: a.created_by == u.user_id)
    |> join(:inner, [a, u], r in UserRole, on: r.user_id == u.id)
    |> join(:inner, [a, u, r, c], c in Class, on: c.id == a.class_id)
    |> where([a, u, r], r.role_id == @student_role)
    |> select([a, u, r, c], %{class_id: c.id})
  end
end