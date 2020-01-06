defmodule Skoller.Schools.SchoolAnalytics do
  alias Skoller.Repo
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Schools.School
  alias Skoller.Classes.Class
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Schools.EmailDomain

  import Ecto.Query

  def get_analytics() do
    from(s in School)
    |> join(:left, [s], d in subquery(email_domains_subquery()), on: d.school_id == s.id)
    |> join(:left, [s], a_t in subquery(accounts_in_active_terms_subquery()),
      on: a_t.school_id == s.id
    )
    |> join(:left, [s], i_t in subquery(accounts_in_inactive_terms_subquery()),
      on: i_t.school_id == s.id
    )
    |> join(:left, [s], t_a in subquery(accounts_per_school_subquery()), on: t_a.school_id == s.id)
    |> order_by([s], s.inserted_at)
    |> select([s, d, a_t, i_t, t_a], [
      fragment("to_char(?, 'MM/DD/YYYY HH24:MI:SS')", s.inserted_at),
      s.name,
      s.adr_locality,
      s.adr_region,
      s.timezone,
      d.domains,
      s.color,
      a_t.count,
      i_t.count,
      t_a.count
    ])
    |> Repo.all()
  end

  defp email_domains_subquery() do
    from(d in EmailDomain)
    |> group_by([d], d.school_id)
    |> select([d], %{school_id: d.school_id, domains: fragment("string_agg(email_domain, '|')")})
  end

  defp accounts_per_school_subquery() do
    account_school_subquery =
      from(sc in StudentClass)
      |> join(:inner, [sc], c in Class, on: c.id == sc.class_id)
      |> join(:inner, [sc, c], p in ClassPeriod, on: p.id == c.class_period_id)
      |> where([sc], sc.is_dropped == false)
      |> distinct(true)
      |> select([sc, c, p], %{school_id: p.school_id, student_id: sc.student_id})

    from(r in subquery(account_school_subquery))
    |> group_by([r], r.school_id)
    |> select([r], %{school_id: r.school_id, count: count(r.school_id)})
  end

  defp accounts_in_active_terms_subquery(), do: class_period_base_query(true)
  defp accounts_in_inactive_terms_subquery(), do: class_period_base_query(false)

  defp class_period_base_query(is_active) do
    current_date =
      DateTime.utc_now()
      |> DateTime.to_date()
      |> Date.to_string()

    current_datetime =
      (current_date <> " 00:00:00Z")
      |> DateTime.from_iso8601()
      |> Kernel.elem(1)
      |> DateTime.to_string()

    distinct_users_subquery =
      from(p in ClassPeriod)
      |> join(:inner, [p], c in Class, on: c.class_period_id == p.id)
      |> join(:inner, [p, c], sc in StudentClass, on: sc.class_id == c.id)
      |> filter_active_type(is_active, current_datetime)
      |> where([p, c, sc], sc.is_dropped == false)
      |> distinct(true)
      |> select([p, c, sc], %{school_id: p.school_id, student_id: sc.student_id})

    from(e in subquery(distinct_users_subquery))
    |> group_by([e], e.school_id)
    |> select([e], %{school_id: e.school_id, count: count(e.school_id)})
  end

  defp filter_active_type(query, false, current_datetime),
    do: where(query, [p], p.end_date < ^current_datetime)

  defp filter_active_type(query, true, current_datetime),
    do: where(query, [p], p.start_date <= ^current_datetime and p.end_date >= ^current_datetime)
end
