defmodule Skoller.StudentClasses.Docs do
  @moduledoc """
  A context module for enrolled classes with docs.
  """

  alias Skoller.Repo
  alias Skoller.Classes.Class
  alias Skoller.Classes.Schools
  alias Skoller.Classes.Docs

  import Ecto.Query

  @doc """
  Get a count of classes with syllabi and at least one student between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
  * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  """
  def get_enrolled_class_with_syllabus_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> join(:inner, [c, cs], d in subquery(Docs.classes_with_syllabus_subquery()), d.class_id == c.id)
    |> where([c], fragment("exists(select 1 from student_classes sc where sc.class_id = ? and sc.is_dropped = false)", c.id))
    |> where([c, cs, d], fragment("?::date", d.inserted_at) >= ^date_start and fragment("?::date", d.inserted_at) <= ^date_end)
    |> Repo.aggregate(:count, :id)
  end
end