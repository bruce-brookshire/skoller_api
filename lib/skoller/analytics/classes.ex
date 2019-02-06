defmodule Skoller.Analytics.Classes do
  @moduledoc """
  A context module for running analytics on classes
  """

  alias Skoller.Classes.Class
  alias Skoller.Classes.Schools
  alias Skoller.Schools.School
  alias Skoller.Repo
  alias Skoller.Periods.ClassPeriod
  alias Skoller.ClassStatuses
  alias Skoller.Periods.Status
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


  def get_community_classes() do
    from(p in ClassPeriod)
    |> join(:inner, [p], ps in Status, p.class_period_status_id == ps.id)
    |> join(:inner, [p, ps], c in Class, c.class_period_id == p.id)
    |> join(:inner, [p, ps, c], cs in ClassStatuses.Status, c.class_status_id  == cs.id)
    |> join(:inner, [p, ps, c, cs], s in School, p.school_id == s.id)
    |> join(:left, [p, ps, c, cs, s], sc_a in subquery(get_student_classes_active_subquery()), c.id == sc_a.class_id)
    |> join(:left, [p, ps, c, cs, s, sc_a], sc_i in subquery(get_student_classes_inactive_subquery()), c.id == sc_i.class_id)
    |> where([p, ps, c, cs, s, sc_a, sc_i], not(is_nil(sc_a.active) and is_nil(sc_i.inactive)))
    |> select([p, ps, c, cs, s, sc_a, sc_i], %{created_on: c.inserted_at, is_student_created: c.is_student_created, term_name: p.name, term_status: ps.name, class_name: c.name, class_status: cs.name, active: sc_a.active, inactive: sc_i.inactive, school_name: s.name})
    |> Repo.all()
  end


  defp get_student_classes_active_subquery() do
    from(s in StudentClass)
      |> where([s], s.is_dropped == false)
      |> group_by([s], s.class_id)
      |> select([s], %{class_id: s.class_id, active: count(s.class_id)})
  end

  defp get_student_classes_inactive_subquery() do
    from(s in StudentClass)
      |> where([s], s.is_dropped == true)
      |> group_by([s], s.class_id)
      |> select([s], %{class_id: s.class_id, inactive: count(s.class_id)})
  end
end