defmodule Skoller.Analytics.Docs do
  @moduledoc """
  A context module for enrolled classes with docs.
  """

  alias Skoller.Repo
  alias Skoller.Classes.Class
  alias Skoller.Classes.Schools
  alias Skoller.ClassDocs.Doc

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
    |> join(:inner, [c, cs], d in subquery(classes_with_syllabus_subquery()), d.class_id == c.id)
    |> where([c], fragment("exists(select 1 from student_classes sc where sc.class_id = ? and sc.is_dropped = false)", c.id))
    |> where([c, cs, d], fragment("?::date", d.inserted_at) >= ^date_start and fragment("?::date", d.inserted_at) <= ^date_end)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Get a count of classes with multiple files and at least one student between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
  * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  """
  def classes_multiple_files(dates, params) do
    from(d in Doc)
    |> join(:inner, [d], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == d.class_id)
    |> where([d], fragment("?::date", d.inserted_at) >= ^dates.date_start and fragment("?::date", d.inserted_at) <= ^dates.date_end)
    |> where([d], fragment("exists(select 1 from student_classes sc where sc.class_id = ? and sc.is_dropped = false)", d.class_id))
    |> group_by([d], d.class_id)
    |> having([d], count(d.class_id) > 1)
    |> select([d], count(d.class_id, :distinct))
    |> Repo.all()
    |> Enum.count()
  end

  # Gets oldest syllabus in each class.
  defp classes_with_syllabus_subquery() do
    from(d in Doc)
    |> where([d], d.is_syllabus == true)
    |> distinct([d], d.class_id)
    |> order_by([d], asc: d.inserted_at)
  end
end