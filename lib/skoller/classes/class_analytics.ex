defmodule Skoller.Classes.ClassAnalytics do
  @moduledoc false

  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Schools.School
  alias Skoller.Assignments.Assignment
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.ClassStatuses.Status
  alias Skoller.Mods.Action
  alias Skoller.Mods.Mod
  alias Skoller.Repo

  import Ecto.Query

  def get_analytics() do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, on: p.id == c.class_period_id)
    |> join(:inner, [c, p], s in School, on: s.id == p.school_id)
    |> join(:left, [c], a_c in subquery(assignment_count_subquery()), on: a_c.class_id == c.id)
    |> join(:left, [c], a_g in subquery(assignment_graded_count_subquery()),
      on: a_g.class_id == c.id
    )
    |> join(:left, [c], m_c in subquery(modifications_created_count_subquery()),
      on: m_c.class_id == c.id
    )
    |> join(:left, [c], m_a in subquery(modification_action_count_subquery()),
      on: m_a.class_id == c.id
    )
    |> join(:left, [c], c_a in subquery(student_class_subquery(true)), on: c_a.class_id == c.id)
    |> join(:left, [c], c_i in subquery(student_class_subquery(false)), on: c_i.class_id == c.id)
    |> join(:left, [c], l_e in subquery(enrolled_through_link()), on: l_e.class_id == c.id)
    |> join(:left, [c], st in Status, on: c.class_status_id == st.id)
    |> order_by([c], desc: c.inserted_at)
    |> select([c, p, s, a_c, a_g, m_c, m_a, c_a, c_i, l_e, st], [
      fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", c.inserted_at),
      c.name,
      st.name,
      s.name,
      p.name,
      p.name,
      c_a.count,
      c_i.count,
      l_e.count,
      a_c.count,
      m_c.count,
      m_a.count,
      a_g.count,
      c.id
    ])
    |> Repo.all()
  end

  defp student_class_subquery(is_active) do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == not (^is_active))
    |> group_by([sc], sc.class_id)
    |> select([sc], %{class_id: sc.class_id, count: count(sc.class_id)})
  end

  defp assignment_count_subquery() do
    from(a in Assignment)
    |> group_by([a], a.class_id)
    |> select([a], %{class_id: a.class_id, count: count(a.class_id)})
  end

  defp assignment_graded_count_subquery() do
    from(a in Assignment)
    |> join(:inner, [a], sa in StudentAssignment, on: sa.assignment_id == a.id)
    |> where([a, sa], not is_nil(sa.grade))
    |> group_by([a], a.class_id)
    |> select([a], %{class_id: a.class_id, count: count(a.class_id)})
  end

  defp modifications_created_count_subquery() do
    from(a in Assignment)
    |> join(:inner, [a], m in Mod, on: m.assignment_id == a.id)
    |> group_by([a, m], a.class_id)
    |> select([a, m], %{class_id: a.class_id, count: count(a.class_id)})
  end

  defp modification_action_count_subquery() do
    from(sc in StudentClass)
    |> join(:inner, [sc], a in Action, on: a.student_class_id == sc.id)
    |> where([sc, a], not is_nil(a.is_accepted))
    |> group_by([sc, a], sc.class_id)
    |> select([sc, a], %{class_id: sc.class_id, count: count(sc.class_id)})
  end

  defp enrolled_through_link() do
    from(sc in StudentClass)
    |> where([sc], not is_nil(sc.enrolled_by_id))
    |> group_by([sc], sc.class_id)
    |> select([sc], %{class_id: sc.class_id, count: count(sc.class_id)})
  end
end
