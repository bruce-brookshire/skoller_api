defmodule Skoller.Analytics.Classes do
  @moduledoc """
  A context module for running analytics on classes
  """

  alias Skoller.Classes.Class
  alias Skoller.Classes.Schools
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Gets a count of classes created between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  
  """
  def get_class_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^date_start and fragment("?::date", c.inserted_at) <= ^date_end)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a count of student created classes created between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  
  """
  def student_created_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^date_start and fragment("?::date", c.inserted_at) <= ^date_end)
    |> where([c], c.is_student_created == true)
    |> Repo.aggregate(:count, :id)
  end
end