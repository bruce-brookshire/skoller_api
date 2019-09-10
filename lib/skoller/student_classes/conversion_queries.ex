defmodule Skoller.StudentClasses.ConversionQueries do
  @moduledoc """
  A context module for enrolled students in class statuses.
  """

  alias Skoller.Repo
  alias Skoller.Users.User
  alias Skoller.Classes.Class
  alias Skoller.Schools.School
  alias Skoller.EnrolledStudents
  alias Skoller.Periods.ClassPeriod
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.CustomSignups.Signup
  alias Skoller.Organizations.Organization
  alias Skoller.Analytics.Classes, as: AnalyticsClasses

  import Ecto.Query

  @days_of_week ["M", "T", "W", "R", "F", "S", "U"]

  @party_size 4

  @needs_setup_status_id 1100
  @class_setup_status_id 1400
  @class_issue_status_id 1500

  @doc """
  Gets a list of users that are not enrolled in a class.
  """
  def get_unenrolled_users() do
    from(u in User)
    |> join(:left, [u], sc in subquery(EnrolledStudents.enrolled_student_class_subquery()),
      on: sc.student_id == u.student_id
    )
    |> join(:left, [u, sc], sl in Signup, on: u.student_id == sl.student_id)
    |> join(:left, [u, sc, sl], o in Organization,
      on: sl.custom_signup_link_id == o.custom_signup_link_id
    )
    |> where([u, sc, sl, o], is_nil(sc.id) and not is_nil(u.student_id))
    |> select([u, sc, sl, o], %{
      user: u,
      opts: %{org_name: o.name}
    })
    |> Repo.all()
  end

  @doc """
  Gets a list of users that have classes that need setup at the class start time.
  """
  def get_users_needs_setup_classes() do
    day_str = Enum.at(@days_of_week, Date.day_of_week(Date.utc_today()) - 1)
    day_of_week = "%#{day_str}%"

    Time.utc_now() |> IO.inspect()

    base_student_class_query()
    |> where(
      [c, cp, s, sc, u, sl, o],
      c.class_status_id == @needs_setup_status_id and sc.is_dropped == false
    )
    |> where(fragment("meet_days LIKE ?", ^day_of_week))
    |> where(fragment("meet_start_time <= (CURRENT_TIME(0) AT TIME ZONE timezone)::time"))
    |> select([c, cp, s, sc, u, sl, o], %{
      user: u,
      opts: %{org_name: o.name, class_name: c.name}
    })
    |> Repo.all()
    |> IO.inspect
    base_student_class_query()
    |> where(
      [c, cp, s, sc, u, sl, o],
      c.class_status_id == @needs_setup_status_id and sc.is_dropped == false
    )
    |> where(fragment("meet_days LIKE ?", ^day_of_week))
    |> where(
      fragment(
        "meet_start_time > ((CURRENT_TIME(0) - INTERVAL '1 minutes' * 5) AT TIME ZONE timezone)::time"
      )
    )
    |> select([c, cp, s, sc, u, sl, o], %{
      user: u,
      opts: %{org_name: o.name, class_name: c.name}
    })
    |> Repo.all()
    |> IO.inspect

    base_student_class_query()
    |> where(
      [c, cp, s, sc, u, sl, o],
      c.class_status_id == @needs_setup_status_id and sc.is_dropped == false
    )
    |> where(fragment("meet_days LIKE ?", ^day_of_week))
    |> where(fragment("meet_start_time <= (CURRENT_TIME(0) AT TIME ZONE timezone)::time"))
    |> where(
      fragment(
        "meet_start_time > ((CURRENT_TIME(0) - INTERVAL '1 minutes' * 5) AT TIME ZONE timezone)::time"
      )
    )
    |> select([c, cp, s, sc, u, sl, o], %{
      user: u,
      opts: %{org_name: o.name, class_name: c.name}
    })
    |> Repo.all()
  end

  @doc """
  Gets a list of users that have are enrolled in a class with less than 4 people at the class start time.
  """
  def get_users_grow_community_classes() do
    day_str = Enum.at(@days_of_week, Date.day_of_week(Date.utc_today()) - 1)
    day_of_week = "%#{day_str}%"

    base_student_class_query()
    |> join(
      :left,
      [c, cp, s, sc, u, sl, o],
      active_students in subquery(AnalyticsClasses.get_student_classes_active_subquery()),
      on: c.id == active_students.class_id
    )
    |> where(
      [c, cp, s, sc, u, sl, o, a],
      (c.class_status_id == @class_setup_status_id or c.class_status_id == @class_issue_status_id) and
        sc.is_dropped == false and a.active < @party_size
    )
    |> where(fragment("meet_days LIKE ?", ^day_of_week))
    |> where(fragment("meet_start_time <= (CURRENT_TIME(0) AT TIME ZONE timezone)::time"))
    |> where(
      fragment(
        "meet_start_time > ((CURRENT_TIME(0) - INTERVAL '1 minutes' * 5) AT TIME ZONE timezone)::time"
      )
    )
    |> select([c, cp, s, sc, u, sl, o, a], %{
      user: u,
      opts: %{org_name: o.name, class_name: c.name, student_class_link: sc.enrollment_link}
    })
    |> Repo.all()
  end

  @doc """
  Gets a list of users that have only one class setup and no other classes, so they can join the next one.
  """
  def get_users_join_second_class() do
    base_student_class_query()
    |> join(
      :inner,
      [c, cp, s, sc, u, sl, o],
      a_s in subquery(student_enrollment_setup_subquery()),
      on: a_s.student_id == u.student_id
    )
    |> join(
      :left,
      [c, cp, s, sc, u, sl, o, a_s],
      a_n in subquery(student_enrollment_not_setup_subquery()),
      on: a_n.student_id == u.student_id
    )
    |> join(
      :left,
      [c, cp, s, sc, u, sl, o, a_s, a_n],
      class_stat in subquery(party_sized_classes_subquery()),
      on: c.id == class_stat.class_id
    )
    |> where(
      [c, cp, s, sc, u, sl, o, a_s, a_n, c_stat],
      a_s.enrollment_count == 1 and (is_nil(a_n.enrollment_count) or a_n.enrollment_count == 0) and
        sc.is_dropped == false
    )
    |> where(fragment("meet_start_time <= (CURRENT_TIME(0) AT TIME ZONE timezone)::time"))
    |> where(
      fragment(
        "meet_start_time > ((CURRENT_TIME(0) - INTERVAL '1 minutes' * 5) AT TIME ZONE timezone)::time"
      )
    )
    |> where([c, cp, s, sc, u, sl, o, a_s, a_n, c_stat], c_stat.count >= @party_size)
    |> select([c, cp, s, sc, u, sl, o, a_s, a_n, c_stat], %{
      user: u,
      opts: %{org_name: o.name}
    })
    |> Repo.all()
  end

  # student_class_link

  defp base_student_class_query() do
    from(c in Class)
    |> join(:left, [c], cp in ClassPeriod, on: cp.id == c.class_period_id)
    |> join(:left, [c, cp], s in School, on: cp.school_id == s.id)
    |> join(:inner, [c, cp, s], sc in StudentClass, on: c.id == sc.class_id)
    |> join(:left, [c, cp, s, sc], u in User, on: sc.student_id == u.student_id)
    |> join(:left, [c, cp, s, sc, u], sl in Signup, on: u.student_id == sl.student_id)
    |> join(:left, [c, cp, s, sc, u, sl], o in Organization,
      on: sl.custom_signup_link_id == o.custom_signup_link_id
    )
  end

  defp student_enrollment_setup_subquery() do
    from(sc in StudentClass)
    |> join(:inner, [sc], c in Class, on: c.id == sc.class_id)
    |> where([sc, c], sc.is_dropped == false and c.class_status_id == @class_setup_status_id)
    |> group_by([sc, c], sc.student_id)
    |> select([sc, c], %{student_id: sc.student_id, enrollment_count: count(sc.student_id)})
  end

  defp student_enrollment_not_setup_subquery() do
    from(sc in StudentClass)
    |> join(:inner, [sc], c in Class, on: c.id == sc.class_id)
    |> where([sc, c], sc.is_dropped == false and c.class_status_id != @class_setup_status_id)
    |> group_by([sc, c], sc.student_id)
    |> select([sc, c], %{student_id: sc.student_id, enrollment_count: count(sc.student_id)})
  end

  defp party_sized_classes_subquery() do
    from(sc in StudentClass)
    |> group_by([sc], sc.class_id)
    |> select([sc], %{class_id: sc.class_id, count: count(sc.class_id)})
  end
end
