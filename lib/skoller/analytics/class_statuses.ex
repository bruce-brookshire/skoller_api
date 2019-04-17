defmodule Skoller.Analytics.ClassStatuses do
  @moduledoc """
  Analytics for class statuses.
  """

  alias Skoller.Repo
  alias Skoller.Classes.Class
  alias Skoller.Classes.Schools

  import Ecto.Query

  @needs_setup_status 1100
  @class_complete_status 1400

  @doc """
  Gets a count of completed classes created between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  
  """
  def get_completed_class_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)), on: c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^date_start and fragment("?::date", c.inserted_at) <= ^date_end)
    |> where([c], c.class_status_id == @class_complete_status)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a count of classes in review (has syllabus but not complete) created between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  
  """
  def get_class_in_review_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)), on: c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^date_start and fragment("?::date", c.inserted_at) <= ^date_end)
    |> where([c], c.class_status_id != @class_complete_status and c.class_status_id > @needs_setup_status)
    |> Repo.aggregate(:count, :id)
  end
end