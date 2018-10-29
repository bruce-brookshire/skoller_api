defmodule Skoller.Analytics do
  @moduledoc """
  A context module for running analytics on the platform.
  """

  alias Skoller.Analytics.ClassStatuses
  alias Skoller.Analytics.DIY
  alias Skoller.Analytics.Enrollment
  alias Skoller.Analytics.Students
  alias Skoller.Analytics.Classes
  alias Skoller.Analytics.Docs
  alias Skoller.Analytics.Assignments
  alias Skoller.Analytics.Chats
  alias Skoller.Analytics.Grades
  alias Skoller.Analytics.Mods

  @semester_days 112

  @num_notification_time 3

  def get_analytics_summary(params) do
    start_date = Date.from_iso8601!(params["date_start"])
    end_date = Date.from_iso8601!(params["date_end"])
    range_days = Date.diff(end_date, start_date)

    dates = Map.new 
            |> Map.put(:date_start, start_date)
            |> Map.put(:date_end, end_date)

    completed_classes = ClassStatuses.get_completed_class_count(dates, params)
    completed_by_diy = DIY.classes_completed_by_diy_count(dates, params)
    avg_classes = Enrollment.avg_classes_per_student(dates, params)
    avg_days_out = Students.get_avg_notification_days_notice(params)
    notifications_enabled = Students.get_notifications_enabled(params)
    reminder_notifications_enabled = Students.get_reminder_notifications_enabled(params)

    class = Map.new()
    |> Map.put(:class_count, Classes.get_class_count(dates, params))
    |> Map.put(:enrollment, Enrollment.enrollment_count(dates, params))
    |> Map.put(:completed_class, completed_classes)
    |> Map.put(:communitites, Enrollment.communitites(dates, params))
    |> Map.put(:class_in_review, ClassStatuses.get_class_in_review_count(dates, params))
    |> Map.put(:completed_by_diy, completed_by_diy)
    |> Map.put(:completed_by_skoller, completed_classes - completed_by_diy)
    |> Map.put(:enrolled_class_syllabus_count, Docs.get_enrolled_class_with_syllabus_count(dates, params))
    |> Map.put(:classes_multiple_files, Docs.classes_multiple_files(dates, params))
    |> Map.put(:student_created_classes, Classes.student_created_count(dates, params))
    |> Map.put(:avg_classes, avg_classes)

    assignment = Map.new()
    |> Map.put(:assign_count, Assignments.get_assignment_count(dates, params))
    |> Map.put(:assign_due_date_count, Assignments.get_assignments_with_due_date_count(dates, params))
    |> Map.put(:skoller_assign_count, Assignments.get_skoller_assignment_count(dates, params))
    |> Map.put(:student_assign_count, Assignments.student_assign_count(dates, params))

    assign_per_student = average_assign_per_student(class, assignment)

    assignment = assignment
    |> Map.put(:assign_per_student, assign_per_student)

    chat = Map.new()
    |> Map.put(:chat_classes, Chats.get_classes_with_chat_count(dates, params))
    |> Map.put(:chat_post_count, Chats.get_chat_post_count(dates, params))
    |> Map.put(:max_chat_activity, Chats.get_max_chat_activity(dates, params) |> create_max_chat_activity_map())
    |> Map.put(:participating_students, Chats.get_chat_participating_students_count(dates, params))

    estimated_reminders = avg_classes * assign_per_student * (avg_days_out + 1) * reminder_notifications_enabled
    estimated_reminders_period = (range_days / @semester_days) * estimated_reminders

    notifications = Map.new()
    |> Map.put(:avg_days_out, avg_days_out)
    |> Map.put(:common_times, Students.get_common_notification_times(@num_notification_time, params))
    |> Map.put(:notifications_enabled, notifications_enabled)
    |> Map.put(:mod_notifications_enabled, Students.get_mod_notifications_enabled(params))
    |> Map.put(:reminder_notifications_enabled, reminder_notifications_enabled)
    |> Map.put(:chat_notifications_enabled, Students.get_chat_notifications_enabled(params))
    |> Map.put(:student_class_notifications_enabled, Students.get_student_class_notifications_enabled(params))
    |> Map.put(:estimated_reminders, estimated_reminders)
    |> Map.put(:estimated_reminders_period, estimated_reminders_period)
    |> Map.put(:students, Students.get_enrolled_student_count(params))

    grades = Map.new()
    |> Map.put(:grades_entered, Grades.get_grades_entered_count(params))
    |> Map.put(:student_classes_with_grades, Grades.get_student_classes_with_grades_count(params))
    |> Map.put(:student_classes, Enrollment.get_enrollment_count(params))

    Map.new()
    |> Map.put(:class, class)
    |> Map.put(:assignment, assignment)
    |> Map.put(:mod, Mods.mod_analytics_summary_by_type(dates, params))
    |> Map.put(:chat, chat)
    |> Map.put(:notifications, notifications)
    |> Map.put(:grades, grades)
  end

  defp average_assign_per_student(%{completed_class: 0}, _assign), do: 0
  defp average_assign_per_student(class, assign) do
    Kernel.div(assign.assign_count, class.completed_class) * class.avg_classes
  end

  defp create_max_chat_activity_map(nil) do
    Map.new()
    |> Map.put(:class_name, "")
    |> Map.put(:count, 0)
  end
  defp create_max_chat_activity_map(class) do
    Map.new()
    |> Map.put(:class_name, class.class.name)
    |> Map.put(:count, class.count)
  end
end