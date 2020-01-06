defmodule Skoller.Students.StudentAnalytics do
  alias Skoller.Repo
  alias Skoller.Users.User
  alias Skoller.Students.Student
  alias Skoller.Schools.School
  alias Skoller.Sessions.Session
  alias Skoller.CustomSignups.Signup
  alias Skoller.CustomSignups.Link
  alias Skoller.Periods.ClassPeriod
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.StudentPoints.StudentPoint
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Assignments.Assignment
  alias Skoller.Classes.Class
  alias Skoller.Mods.Action
  alias Skoller.Mods.Mod
  alias Skoller.Students.FieldOfStudy, as: StudentField
  alias Skoller.FieldsOfStudy.FieldOfStudy

  import Ecto.Query

  @signup_point_type_id 2
  @class_setup_status_id 1400
  @class_issue_status_id 1500

  def get_analytics() do
    analytics_query()
  end

  defp analytics_query() do
    active_sc_subq = subquery(active_student_classes_subquery())
    inactive_sc_subq = subquery(inactive_student_classes_subquery())

    #### LEGEND ####
    # sc_a: active student classes
    # sc_a_s: active student classes setup
    # a_a: active assignments
    # a_a_g: active assignments with grades
    # a_m_c_c: active modifications created
    # a_m_a_c: active modication actions
    # sc_i: inactive student classes
    # sc_i_s: inactive student classes setup
    # a_i: inactive assignments
    # a_i_g: inactive assignments with grades
    # i_m_c_c: inactive modifications created
    # i_m_a_c: inactive modication actions

    from(u in User)
    |> join(:inner, [u], s in Student, on: s.id == u.student_id)
    |> join(:left, [u, s], cs in Signup, on: cs.student_id == s.id)
    |> join(:left, [u, s, cs], cl in Link, on: cl.id == cs.custom_signup_link_id)
    |> join(:left, [u, s], sc in School, on: sc.id == s.primary_school_id)
    |> join(:left, [u, s, sc], se in subquery(recent_session_subquery()), on: se.user_id == u.id)
    |> join(:left, [u, s, sc, se], sp in subquery(referral_signup_count_subquery()),
      on: s.id == sp.student_id
    )
    |> join(:left, [u, s], sc_a in subquery(classes_count_subquery(active_sc_subq)),
      on: sc_a.student_id == s.id
    )
    |> join(:left, [u, s], sc_a_s in subquery(classes_setup_count_subquery(active_sc_subq)),
      on: sc_a_s.student_id == s.id
    )
    |> join(:left, [u, s], a_a in subquery(assignments_count_subquery(active_sc_subq)),
      on: a_a.student_id == s.id
    )
    |> join(:left, [u, s], a_a_g in subquery(assignments_graded_count_subquery(active_sc_subq)),
      on: a_a_g.student_id == s.id
    )
    |> join(
      :left,
      [u, s],
      a_m_c_c in subquery(modifications_created_count_subquery(active_sc_subq)),
      on: a_m_c_c.student_id == s.id
    )
    |> join(
      :left,
      [u, s],
      a_m_a_c in subquery(modification_actions_count_subquery(active_sc_subq)),
      on: a_m_a_c.student_id == s.id
    )
    |> join(:left, [u, s], sc_i in subquery(classes_count_subquery(inactive_sc_subq)),
      on: sc_i.student_id == s.id
    )
    |> join(:left, [u, s], sc_i_s in subquery(classes_setup_count_subquery(inactive_sc_subq)),
      on: sc_i_s.student_id == s.id
    )
    |> join(:left, [u, s], i_a in subquery(assignments_count_subquery(inactive_sc_subq)),
      on: i_a.student_id == s.id
    )
    |> join(:left, [u, s], i_a_g in subquery(assignments_graded_count_subquery(inactive_sc_subq)),
      on: i_a_g.student_id == s.id
    )
    |> join(
      :left,
      [u, s],
      i_m_c_c in subquery(modifications_created_count_subquery(active_sc_subq)),
      on: i_m_c_c.student_id == s.id
    )
    |> join(
      :left,
      [u, s],
      i_m_a_c in subquery(modification_actions_count_subquery(inactive_sc_subq)),
      on: i_m_a_c.student_id == s.id
    )
    |> join(:left, [u, s], f in subquery(aggregated_majors_subquery()), on: f.student_id == s.id)
    |> select(
      [
        u,
        s,
        cs,
        cl,
        sc,
        se,
        sp,
        sc_a,
        sc_a_s,
        a_a,
        a_a_g,
        a_m_c_c,
        a_m_a_c,
        sc_i,
        sc_i_s,
        i_a,
        i_a_g,
        i_m_c_c,
        i_m_a_c,
        f
      ],
      [
        fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", u.inserted_at),
        cl.link,
        sp.count,
        s.name_first,
        s.name_last,
        u.email,
        s.phone,
        sc.name,
        sc.adr_locality,
        sc.adr_region,
        s.grad_year,
        f.fields,
        s.id,
        fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", se.inserted_at),
        sc_a.count,
        sc_a_s.count,
        a_a.count,
        a_a_g.count,
        a_m_c_c.count,
        a_m_a_c.count,
        sc_i.count,
        sc_i_s.count,
        i_a.count,
        i_a_g.count,
        i_m_c_c.count,
        i_m_a_c.count
      ]
    )
    |> Repo.all()
  end

  defp recent_session_subquery() do
    from(s in Session)
    |> order_by([s], desc: s.user_id, desc: s.inserted_at)
    |> distinct([s], s.user_id)
    |> select([s], %{user_id: s.user_id, inserted_at: s.inserted_at})
  end

  defp referral_signup_count_subquery() do
    from(p in StudentPoint)
    |> group_by([p], p.student_id)
    |> where([p], p.student_point_type_id == @signup_point_type_id)
    |> select([p], %{student_id: p.student_id, count: count(p.student_id)})
  end

  defp aggregated_majors_subquery() do
    from(f in FieldOfStudy)
    |> join(:inner, [f], sf in StudentField, on: sf.field_of_study_id == f.id)
    |> group_by([f, sf], sf.student_id)
    |> select([f, sf], %{student_id: sf.student_id, fields: fragment("string_agg(field, '|')")})
  end

  # Classes subqueries
  def classes_count_subquery(sc_subq) do
    from(sc in sc_subq)
    |> group_by([sc], sc.student_id)
    |> select([sc], %{student_id: sc.student_id, count: count(sc.student_id)})
  end

  defp classes_setup_count_subquery(sc_subq) do
    from(sc in sc_subq)
    |> join(:inner, [sc], c in Class, on: sc.class_id == c.id)
    |> where(
      [sc, c],
      c.class_status_id == @class_setup_status_id or c.class_status_id == @class_issue_status_id
    )
    |> group_by([sc], sc.student_id)
    |> select([sc], %{student_id: sc.student_id, count: count(sc.student_id)})
  end

  defp assignments_count_subquery(sc_subq) do
    from(sc in sc_subq)
    |> join(:inner, [sc], a in StudentAssignment, on: a.student_class_id == sc.id)
    |> group_by([sc], sc.student_id)
    |> select([sc], %{student_id: sc.student_id, count: count(sc.student_id)})
  end

  defp assignments_graded_count_subquery(sc_subq) do
    from(sc in sc_subq)
    |> join(:inner, [sc], a in StudentAssignment, on: a.student_class_id == sc.id)
    |> where([sc, a], not is_nil(a.grade))
    |> group_by([sc], sc.student_id)
    |> select([sc], %{student_id: sc.student_id, count: count(sc.student_id)})
  end

  defp modifications_created_count_subquery(sc_subq) do
    from(sc in sc_subq)
    |> join(:inner, [sc], a in Assignment, on: a.class_id == sc.class_id)
    |> join(:inner, [sc, a], m in Mod,
      on: m.student_id == sc.student_id and m.assignment_id == a.id
    )
    |> group_by([sc, a, m], m.student_id)
    |> select([sc, a, m], %{student_id: m.student_id, count: count(m.student_id)})
  end

  defp modification_actions_count_subquery(sc_subq) do
    from(sc in sc_subq)
    |> join(:inner, [sc], a in Action, on: sc.id == a.student_class_id)
    |> where([sc, a], not is_nil(a.is_accepted))
    |> group_by([sc, a], sc.student_id)
    |> select([sc, a], %{student_id: sc.student_id, count: count(sc.student_id)})
  end

  # Helpers
  defp current_datetime() do
    current_date =
      DateTime.utc_now()
      |> DateTime.to_date()
      |> Date.to_string()

    (current_date <> " 00:00:00Z")
    |> DateTime.from_iso8601()
    |> Kernel.elem(1)
    |> DateTime.to_string()
  end

  defp active_student_classes_subquery() do
    current_datetime = current_datetime()

    from(p in ClassPeriod)
    |> join(:inner, [p], c in Class, on: c.class_period_id == p.id)
    |> join(:inner, [p, c], sc in StudentClass, on: c.id == sc.class_id)
    |> where([p, c, sc], p.start_date <= ^current_datetime and p.end_date >= ^current_datetime)
    |> where([p, c, sc], sc.is_dropped == false)
    |> select([p, c, sc], sc)
  end

  defp inactive_student_classes_subquery() do
    current_datetime = current_datetime()

    from(p in ClassPeriod)
    |> join(:inner, [p], c in Class, on: c.class_period_id == p.id)
    |> join(:inner, [p, c], sc in StudentClass, on: c.id == sc.class_id)
    |> where([p, c, sc], p.end_date < ^current_datetime)
    |> select([p, c, sc], sc)
  end
end
