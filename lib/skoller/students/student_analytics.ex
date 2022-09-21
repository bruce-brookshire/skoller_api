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
  alias Skoller.Payments.Stripe, as: CustomerInfo

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
    subscriptions = subscriptions()
    inactive_users = inactive_users(subscriptions)
    active_users = active_users(subscriptions)

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
    |> join(:left, [u, s], subscription_status in subquery(subscription_status_subquery(active_users, inactive_users)), on: subscription_status.student_id == s.id)
    |> join(:left, [u, s], premium_status in subquery(premium_status_subquery()), on: premium_status.student_id == s.id)
    |> order_by([u, s], desc: u.inserted_at)
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
        f,
        subscription_status,
        premium_status
      ],
      [
          user_created: fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", u.inserted_at),
          signup_route: cl.link,
          successful_invites: sp.count,
          first_name: s.name_first,
          last_name: s.name_last,
          email: u.email,
          phone: s.phone,
          school_name: sc.name,
          school_city: sc.adr_locality,
          school_state: sc.adr_region,
          grad_year: s.grad_year,
          majors: f.fields,
          student_id: s.id,
          last_session: fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", se.inserted_at),
          active_enrolled_classes: sc_a.count,
          active_setup_classes: sc_a_s.count,
          active_assignments: a_a.count,
          active_grades_entered: a_a_g.count,
          active_mods_created: a_m_c_c.count,
          active_mods_responded: a_m_a_c.count,
          inactive_enrolled_classes: sc_i.count,
          inactive_setup_classes: sc_i_s.count,
          inactive_assignments: i_a.count,
          inactive_grades_entered: i_a_g.count,
          inactive_mods_created: i_m_c_c.count,
          inactive_mods_responded: i_m_a_c.count,
          subscription_status: subscription_status.status,
          stripe_customer_id: subscription_status.customer_id,
          premium_enrollment: premium_status.created,
          total_premium_charges: "$0"
      ]
    )
    |> Repo.all()
    |> apply_charges(subscriptions)
    |> Enum.map(& Keyword.values(&1))
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

  def subscription_status_subquery(active_users, inactive_users) do
    from(u in User)
    |> join(:inner, [u], s in Student, on: s.id == u.student_id)
    |> join(:left, [u, s], ci in CustomerInfo, on: ci.user_id == u.id)
    |> select([u, s, ci], %{
      student_id: s.id,
      customer_id: ci.customer_id,
      status: fragment("
        CASE
          WHEN ? AND ? BETWEEN ? AND ? AND NOT ? = ANY(?) THEN 'Trial'
          WHEN ? = ANY(?) AND ? IS NOT NULL THEN 'Premium'
          WHEN ? = false AND ? = ANY(?) THEN 'Expired'
          ELSE 'Inactive'
        END",
        u.trial, ^DateTime.utc_now, u.trial_start, u.trial_end, ci.customer_id, ^active_users,
        ci.customer_id, ^active_users, ci.customer_id,
        u.trial, ci.customer_id, ^inactive_users)
    })
  end

  def premium_status_subquery() do
    from(u in User)
    |> join(:inner, [u], s in Student, on: s.id == u.student_id)
    |> join(:left, [u, s], ci in CustomerInfo, on: ci.user_id == u.id)
    |> select([u, s, ci], %{
      student_id: s.id,
      created: fragment("
        CASE
          WHEN ? = NULL THEN 'N/A' ELSE ? END
      ", ci.inserted_at, fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", ci.inserted_at))
    })
  end

  def get_charges(subscriptions) do
    Enum.reduce(subscriptions, [], fn subsc, acc ->
      {:ok, %Stripe.List{data: cust_charges}} = Stripe.Charge.list(%{customer: subsc.customer})
      charges = Enum.reduce(cust_charges, 0, fn charge, acc ->
        charge.amount + acc
      end)
      refunds = Enum.reduce(cust_charges, 0, fn charge, acc ->
        charge.amount_refunded + acc
      end)
      [
        %{
          customer_id: subsc.customer,
          total_charged: "$#{(charges - refunds) / 100}"
        }
        | acc
      ]
    end)
  end

  def apply_charges(query_results, subscriptions) do
    charges = get_charges(subscriptions)
    Enum.map(query_results, fn result ->
      cust_id = Keyword.get(result, :stripe_customer_id, nil)
      if !is_nil(cust_id) do
        customer_charge = Enum.find(charges, fn charge -> charge.customer_id == cust_id end)
        if !is_nil(customer_charge) do
          Keyword.replace(result, :total_premium_charges, customer_charge.total_charged)
        else
          result
        end
      else
        result
      end
    end)
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

  defp subscriptions do
    {:ok, %Stripe.List{data: subscriptions}} = Stripe.Subscription.list(%{status: "all"})
    subscriptions
  end

  defp inactive_users(subscriptions) do
    subscriptions
    |> Enum.reject(&(&1.status == "active"))
    |> Enum.map(&(&1.customer))
  end

  defp active_users(subscriptions) do
    subscriptions
    |> Enum.reject(&(&1.status != "active"))
    |> Enum.map(&(&1.customer))
  end
end
