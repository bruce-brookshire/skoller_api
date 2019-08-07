defmodule Skoller.EnrolledStudents.ClassStatuses do
  @moduledoc """
  A context module for enrolled students in class statuses.
  """

  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.EnrolledStudents
  alias Skoller.ClassStatuses.Classes
  alias Skoller.Users.User
  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Schools.School
  alias Skoller.StudentClasses.StudentClass

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
    |> join(:left, [class, class_period, school, student_class], student in Student,
      on: student.id == student_class.student_id
    )
    |> join(:left, [class, class_period, school, student_class, student], user in User,
      on: student.id == user.student_id
    )
    |> where(
      [class, class_period, school, student_class, student, user],
      class.class_status_id == @needs_setup_status_id and student_class.is_dropped == false
    )
    |> where(fragment("meet_days LIKE ?", ^day_of_week))
    |> where(fragment("meet_start_time <= (CURRENT_TIME AT TIME ZONE timezone)::time"))
    |> where(
      fragment(
        "meet_start_time > ((CURRENT_TIME - INTERVAL '1 minutes' * 5) AT TIME ZONE timezone)::time"
      )
    )
    |> select([class, class_period, school, student_class, student, user], %{
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
    |> join(:left, [class, class_period, school, student_class], student in Student,
      on: student.id == student_class.student_id
    )
    |> join(:left, [class, class_period, school, student_class, student], user in User,
      on: student.id == user.student_id
    )
    |> where(
      [class, class_period, school, student_class, student, user],
      (class.class_status_id == @class_setup_status_id or
         class.class_status_id == @class_issue_status_id) and student_class.is_dropped == false and
        student_class.enrollment < 4
    )
    |> where(fragment("meet_days LIKE ?", ^day_of_week))
    |> where(fragment("meet_start_time <= (CURRENT_TIME AT TIME ZONE timezone)::time"))
    |> where(
      fragment(
        "meet_start_time > ((CURRENT_TIME - INTERVAL '1 minutes' * 5) AT TIME ZONE timezone)::time"
      )
    )
    |> select([class, class_period, school, student_class, student, user], %{
      user: user,
      class_name: class.name
    })
    |> Repo.all()
  end
end
