defmodule Skoller.Analytics.Assignments do
  @moduledoc """
  A context module for running analytics on assignments
  """

  alias Skoller.Repo
  alias Skoller.Assignments.Assignment
  alias Skoller.Classes.Schools

  import Ecto.Query

  @doc """
  Gets a count of assignments between `dates`

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_assignment_count(dates, params) do
    from(a in Assignment)
    |> join(:inner, [a], c in subquery(Schools.get_school_from_class_subquery(params)), on: a.class_id == c.class_id)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Get a count of non student created assignments that have a due date.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_assignments_with_due_date_count(dates, params) do
    from(a in skoller_created_assignment_subquery(dates, params))
    |> where([a], not(is_nil(a.due)))
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Get a count of non student created assignments.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_skoller_assignment_count(dates, params) do
    from(a in skoller_created_assignment_subquery(dates, params))
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Get a count of student created assignments.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  # TODO: This needs to be updated now that students can do DIY.
  def student_assign_count(dates, params) do
    from(a in Assignment)
    |> join(:inner, [a], c in subquery(Schools.get_school_from_class_subquery(params)), on: a.class_id == c.class_id)
    |> where([a], a.from_mod == true)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  # TODO: This needs to be updated now that students can do DIY.
  defp skoller_created_assignment_subquery(dates, params) do
    from(a in Assignment)
    |> join(:inner, [a], c in subquery(Schools.get_school_from_class_subquery(params)), on: a.class_id == c.class_id)
    |> where([a], a.from_mod == false)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
  end
end