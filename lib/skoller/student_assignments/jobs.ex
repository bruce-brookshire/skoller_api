defmodule Skoller.StudentAssignments.Jobs do
  alias Skoller.Repo
  alias Skoller.Classes.Class
  alias Skoller.Schools.School
  alias Skoller.Periods.ClassPeriod
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.StudentAssignments.StudentAssignment

  import Ecto.Query

  def mark_past_assignments_complete() do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, on: sc.id == sa.student_class_id)
    |> join(:inner, [sa, sc], c in Class, on: sc.class_id == c.id)
    |> join(:inner, [sa, sc, c], p in ClassPeriod, on: c.class_period_id == p.id)
    |> join(:inner, [sa, sc, c, p], s in School, on: p.school_id == s.id)
    |> where(
      [sa, sc, c, p, s],
      sc.is_dropped == false and sa.is_completed == false and not is_nil(s.timezone)
    )
    |> where(
      fragment(
        "(due AT TIME ZONE timezone)::date < (current_timestamp AT TIME ZONE timezone)::date"
      )
    )
    |> select([sa, sc, c, p, s], sa)
    |> Repo.update_all(set: [is_completed: true])
  end
end
