defmodule Skoller.Analytics.Students do
  @moduledoc """
  A context module for analytics on students
  """

  alias Skoller.EnrolledStudents
  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.Classes.Schools
  alias Skoller.Schools.School
  alias Skoller.StudentPoints.StudentPoint

  import Ecto.Query

  @doc """
  Gets the average days out on student days notice before assignment reminders.

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_avg_notification_days_notice(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> Repo.aggregate(:avg, :notification_days_notice)
    |> convert_to_float()
  end

  @doc """
  Gets the number of students with notifications enabled.

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_notifications_enabled(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> where([s], s.is_notifications == true)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the number of students with assignment reminder notifications enabled.

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_reminder_notifications_enabled(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> where([s], s.is_reminder_notifications == true)
    |> where([s], s.is_notifications == true)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the `num` most common notification times and timezone combos.

  ## Params
   * %{"school_id" => school_id}, filters by school.

  ## Returns
  `%{notification_time: Time, timezone: String, count: Integer}` or `[]`
  """
  def get_common_notification_times(num, params) do
    from(s in Student)
    |> join(:inner, [s], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)), on: sc.student_id == s.id)
    |> join(:inner, [s, sc], sfc in subquery(Schools.get_school_from_class_subquery(params)), on: sfc.class_id == sc.class_id)
    |> join(:inner, [s, sc, sfc], sch in School, on: sch.id == sfc.school_id)
    |> group_by([s, sc, sfc, sch], [s.notification_time, sch.timezone])
    |> select([s, sc, sfc, sch], %{notification_time: s.notification_time, timezone: sch.timezone, count: count(s.notification_time)})
    |> order_by([s], desc: count(s.notification_time))
    |> limit([s], ^num)
    |> Repo.all()
  end

  @doc """
  Gets the number of students with mod notifications enabled.

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_mod_notifications_enabled(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> where([s], s.is_mod_notifications == true)
    |> where([s], s.is_notifications == true)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the number of students with chat notifications enabled.

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_chat_notifications_enabled(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> where([s], s.is_chat_notifications == true)
    |> where([s], s.is_notifications == true)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the number of classes with notifications enabled.

  
  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_student_class_notifications_enabled(params) do
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)))
    |> join(:inner, [sc], s in Student, on: sc.student_id == s.id)
    |> where([sc], sc.is_notifications == true)
    |> where([sc, s], s.is_notifications == true)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the number of students in a class
  
  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_enrolled_student_count(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the points per student
  """
  def get_student_points() do
    from(s in Student)
    |> join(:inner, [s], p in StudentPoint, on: s.id == p.student_id)
    |> join(:inner, [s, p], t in Skoller.StudentPoints.PointType, on: p.student_point_type_id == t.id)
    |> join(:inner, [s, p, t], u in Skoller.Users.User, on: s.id == u.student_id)
    |> group_by([s, p, t, u], [s.id, u.id, t.id])
    |> order_by([s, p, t, u], asc: s.name_first)
    |> select([s, p, t, u], %{"student_id" => s.id, "first_name" => s.name_first, "last_name" => s.name_last, "user_email" => u.email, "points" => sum(p.value), "type" =>  t.name})
    |> Repo.all()
  end

  defp convert_to_float(nil), do: 0.0
  defp convert_to_float(val), do: val |> Decimal.round(2) |> Decimal.to_float()
end