defmodule Skoller.EnrolledStudents.ClassStatuses do
  @moduledoc """
  A context module for enrolled students in class statuses.
  """

  alias Skoller.Repo
  alias Skoller.Users.User
  alias Skoller.Classes.Class
  alias Skoller.Schools.School
  alias Skoller.Students.Student
  alias Skoller.EnrolledStudents
  alias Skoller.Periods.ClassPeriod
  alias Skoller.ClassStatuses.Classes
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Analytics.Classes, as: AnalyticsClasses

  import Ecto.Query

  @days_of_week ["M", "T", "W", "R", "F", "S", "U"]
  @needs_setup_status_id 1100
  @class_setup_status_id 1400
  @class_issue_status_id 1500

  @doc """
  Gets a list of students that have classes that need setup.
  """
  def get_students_needs_setup_classes() do
    day_str = Enum.at(@days_of_week, Date.day_of_week(Date.utc_today()) - 1)
    day_of_week = "%#{day_str}%"

    from(class in Class)
    |> join(:left, [class], class_period in ClassPeriod,
      on: class_period.id == class.class_period_id
    )
    |> join(:left, [class, class_period], school in School,
      on: class_period.school_id == school.id
    )
    |> join(:inner, [class, class_period, school], student_class in StudentClass,
      on: class.id == student_class.class_id
    )
    |> join(:left, [class, class_period, school, student_class], user in User,
      on: student_class.student_id == user.student_id
    )
    |> where(
      [class, class_period, school, student_class, user],
      class.class_status_id == @needs_setup_status_id and student_class.is_dropped == false
    )
    |> where(fragment("meet_days LIKE ?", ^day_of_week))
    |> where(fragment("meet_start_time <= (CURRENT_TIME AT TIME ZONE timezone)::time"))
    |> where(
      fragment(
        "meet_start_time > ((CURRENT_TIME - INTERVAL '1 minutes' * 5) AT TIME ZONE timezone)::time"
      )
    )
    |> select([class, class_period, school, student_class, user], %{
      user: user,
      class_name: class.name
    })
    |> Repo.all()
  end

  def get_students_grow_community_classes() do
    day_str = Enum.at(@days_of_week, Date.day_of_week(Date.utc_today()) - 1)
    day_of_week = "%#{day_str}%"

    from(class in Class)
    |> join(:left, [class], class_period in ClassPeriod,
      on: class_period.id == class.class_period_id
    )
    |> join(:left, [class, class_period], school in School,
      on: class_period.school_id == school.id
    )
    |> join(:inner, [class, class_period, school], student_class in StudentClass,
      on: class.id == student_class.class_id
    )
    |> join(:left, [class, class_period, school, student_class], user in User,
      on: student_class.student_id == user.student_id
    )
    |> join(
      :left,
      [class, class_period, school, student_class, user],
      active_students in subquery(AnalyticsClasses.get_student_classes_active_subquery()),
      on: class.id == active_students.class_id
    )
    |> where(
      [class, class_period, school, student_class, user, active_students],
      (class.class_status_id == @class_setup_status_id or
         class.class_status_id == @class_issue_status_id) and student_class.is_dropped == false and
        active_students.active < 4
    )
    |> where(fragment("meet_days LIKE ?", ^day_of_week))
    |> where(fragment("meet_start_time <= (CURRENT_TIME AT TIME ZONE timezone)::time"))
    |> where(
      fragment(
        "meet_start_time > ((CURRENT_TIME - INTERVAL '1 minutes' * 5) AT TIME ZONE timezone)::time"
      )
    )
    |> select([class, class_period, school, student_class, user, active_students], %{
      user: user,
      class_name: class.name
    })
    |> Repo.all()
  end

  def get_users_join_second_class() do
    from(u in User)
    |> join(:inner, [u], a_s in subquery(student_enrollment_setup_subquery()),
      on: a_s.student_id == u.student_id
    )
    |> join(:left, [u, a_s], a_n in subquery(student_enrollment_not_setup_subquery()),
      on: a_n.student_id == u.student_id
    )
    |> join(:left, [u, a_s, a_n], sc in StudentClass, on: sc.student_id == u.student_id)
    |> join(:left, [u, a_s, a_n, sc], c in Class, on: sc.class_id == c.id)
    |> where(
      [u, a_s, a_n, sc, c],
      a_s.enrollment_count == 1 and (is_nil(a_n.enrollment_count) or a_n.enrollment_count == 0) and
        sc.is_dropped == false
    )
    |> where(fragment("meet_start_time <= (CURRENT_TIME AT TIME ZONE timezone)::time"))
    |> where(
      fragment(
        "meet_start_time > ((CURRENT_TIME - INTERVAL '1 minutes' * 5) AT TIME ZONE timezone)::time"
      )
    )
    |> select([u, a_s, a_n, sc, c], u)
    |> Repo.all()
  end

  def student_enrollment_setup_subquery() do
    from(sc in StudentClass)
    |> join(:inner, [sc], c in Class, on: c.id == sc.class_id)
    |> where([sc, c], sc.is_dropped == false and c.class_status_id == @class_setup_status_id)
    |> group_by([sc, c], sc.student_id)
    |> select([sc, c], %{student_id: sc.student_id, enrollment_count: count(sc.student_id)})
  end

  def student_enrollment_not_setup_subquery() do
    from(sc in StudentClass)
    |> join(:inner, [sc], c in Class, on: c.id == sc.class_id)
    |> where([sc, c], sc.is_dropped == false and c.class_status_id != @class_setup_status_id)
    |> group_by([sc, c], sc.student_id)
    |> select([sc, c], %{student_id: sc.student_id, enrollment_count: count(sc.student_id)})
  end
end
