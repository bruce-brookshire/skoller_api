defmodule Skoller.Analytics.Classes do
  @moduledoc """
  A context module for running analytics on classes
  """

  alias Skoller.Classes.Class
  alias Skoller.Classes.Schools
  alias Skoller.Repo
  alias Skoller.StudentClasses.StudentClass

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
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)),
      on: c.id == cs.class_id
    )
    |> where(
      [c],
      fragment("?::date", c.inserted_at) >= ^date_start and
        fragment("?::date", c.inserted_at) <= ^date_end
    )
    |> Repo.aggregate(:count, :id)
  end

  def get_student_classes_active_subquery() do
    from(s in StudentClass)
    |> where([s], s.is_dropped == false)
    |> group_by([s], s.class_id)
    |> select([s], %{class_id: s.class_id, active: count(s.class_id)})
  end
end
