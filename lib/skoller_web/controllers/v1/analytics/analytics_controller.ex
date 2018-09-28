defmodule SkollerWeb.Api.V1.Analytics.AnalyticsController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias SkollerWeb.AnalyticsView
  alias Skoller.ClassDocs.Doc
  alias Skoller.Students.Student
  alias Skoller.Assignments.Assignment
  alias Skoller.Mods.Type, as: ModType
  alias Skoller.Mods.Mod
  alias Skoller.Mods.Action
  alias Skoller.ChatPosts.Post
  alias Skoller.ChatComments.Comment
  alias Skoller.ChatReplies.Reply
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Students
  alias Skoller.Classes
  alias Skoller.Chats
  alias Skoller.Classes.Schools
  alias Skoller.Classes.ClassStatuses, as: StatusClasses
  alias Skoller.Classes.Locks
  alias Skoller.EnrolledStudents

  import SkollerWeb.Plugs.Auth
  import Ecto.Query
  
  @admin_role 200

  @community_enrollment 2

  @semester_days 112

  @num_notification_time 3
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, params) do
    start_date = Date.from_iso8601!(params["date_start"])
    end_date = Date.from_iso8601!(params["date_end"])
    range_days = Date.diff(end_date, start_date)

    dates = Map.new 
            |> Map.put(:date_start, start_date)
            |> Map.put(:date_end, end_date)

    completed_classes = StatusClasses.get_completed_class_count(dates, params)
    completed_by_diy = Locks.classes_completed_by_diy_count(dates, params)
    avg_classes = avg_classes(dates, params)
    avg_days_out = get_avg_days_out(params) |> convert_to_float()
    notifications_enabled = get_notifications_enabled(params)
    reminder_notifications_enabled = get_reminder_notifications_enabled(params)

    class = Map.new()
    |> Map.put(:class_count, Classes.get_class_count(dates, params))
    |> Map.put(:enrollment, enrollment_count(dates, params))
    |> Map.put(:completed_class, completed_classes)
    |> Map.put(:communitites, communitites(dates, params))
    |> Map.put(:class_in_review, StatusClasses.get_class_in_review_count(dates, params))
    |> Map.put(:completed_by_diy, completed_by_diy)
    |> Map.put(:completed_by_skoller, completed_classes - completed_by_diy)
    |> Map.put(:enrolled_class_syllabus_count, Students.get_enrolled_class_with_syllabus_count(dates, params))
    |> Map.put(:classes_multiple_files, classes_multiple_files(dates, params))
    |> Map.put(:student_created_classes, Classes.student_created_count(dates, params))
    |> Map.put(:avg_classes, avg_classes)

    assignment = Map.new()
    |> Map.put(:assign_count, assign_count(dates, params))
    |> Map.put(:assign_due_date_count, assign_due_date_count(dates, params))
    |> Map.put(:skoller_assign_count, skoller_assign_count(dates, params))
    |> Map.put(:student_assign_count, student_assign_count(dates, params))

    assign_per_student = assign_per_student(class, assignment)

    assignment = assignment
    |> Map.put(:assign_per_student, assign_per_student)

    chat = Map.new()
    |> Map.put(:chat_classes, get_chat_classes(dates, params))
    |> Map.put(:chat_post_count, get_chat_post_count(dates, params))
    |> Map.put(:max_chat_activity, get_max_chat_activity(dates, params))
    |> Map.put(:participating_students, get_chat_participating_students(dates, params))

    estimated_reminders = avg_classes * assign_per_student * (avg_days_out + 1) * reminder_notifications_enabled
    estimated_reminders_period = (range_days / @semester_days) * estimated_reminders

    notifications = Map.new()
    |> Map.put(:avg_days_out, avg_days_out)
    |> Map.put(:common_times, Students.get_common_notification_times(@num_notification_time, params))
    |> Map.put(:notifications_enabled, notifications_enabled)
    |> Map.put(:mod_notifications_enabled, get_mod_notifications_enabled(params))
    |> Map.put(:reminder_notifications_enabled, reminder_notifications_enabled)
    |> Map.put(:chat_notifications_enabled, get_chat_notifications_enabled(params))
    |> Map.put(:student_class_notifications_enabled, get_student_class_notifications_enabled(params))
    |> Map.put(:estimated_reminders, estimated_reminders)
    |> Map.put(:estimated_reminders_period, estimated_reminders_period)
    |> Map.put(:students, get_students(params))

    grades = Map.new()
    |> Map.put(:grades_entered, get_grades_entered(params))
    |> Map.put(:student_classes_with_grades, get_participation(params))
    |> Map.put(:student_classes, get_student_classes(params))

    analytics = Map.new()
    |> Map.put(:class, class)
    |> Map.put(:assignment, assignment)
    |> Map.put(:mod, mod_map(dates, params))
    |> Map.put(:chat, chat)
    |> Map.put(:notifications, notifications)
    |> Map.put(:grades, grades)

    render(conn, AnalyticsView, "show.json", analytics: analytics)
  end

  defp get_student_classes(params) do
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)))
    |> Repo.aggregate(:count, :id)
  end

  defp get_participation(params) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)), sc.id == sa.student_class_id)
    |> where([sa], not is_nil(sa.grade))
    |> distinct([sa], [sa.student_class_id])
    |> Repo.aggregate(:count, :id)
  end

  defp get_grades_entered(params) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)), sc.id == sa.student_class_id)
    |> where([sa], not is_nil(sa.grade))
    |> Repo.aggregate(:count, :id)
  end

  defp get_students(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> Repo.aggregate(:count, :id)
  end

  defp get_notifications_enabled(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> where([s], s.is_notifications == true)
    |> Repo.aggregate(:count, :id)
  end

  defp get_student_class_notifications_enabled(params) do
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)))
    |> join(:inner, [sc], s in Student, sc.student_id == s.id)
    |> where([sc], sc.is_notifications == true)
    |> where([sc, s], s.is_notifications == true)
    |> Repo.aggregate(:count, :id)
  end

  defp get_mod_notifications_enabled(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> where([s], s.is_mod_notifications == true)
    |> where([s], s.is_notifications == true)
    |> Repo.aggregate(:count, :id)
  end

  defp get_reminder_notifications_enabled(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> where([s], s.is_reminder_notifications == true)
    |> where([s], s.is_notifications == true)
    |> Repo.aggregate(:count, :id)
  end

  defp get_chat_notifications_enabled(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> where([s], s.is_chat_notifications == true)
    |> where([s], s.is_notifications == true)
    |> Repo.aggregate(:count, :id)
  end

  defp get_avg_days_out(params) do
    from(s in subquery(EnrolledStudents.get_student_subquery(params)))
    |> Repo.aggregate(:avg, :notification_days_notice)
  end

  defp get_chat_participating_students(dates, params) do
    post_students = from(p in Post)
    |> join(:inner, [p], c in subquery(Schools.get_school_from_class_subquery(params)), p.class_id == c.class_id)
    |> where([p], fragment("?::date", p.inserted_at) >= ^dates.date_start and fragment("?::date", p.inserted_at) <= ^dates.date_end)
    |> distinct([p], p.student_id)
    |> select([p], p.student_id)
    |> Repo.all()

    comment_students = from(c in Comment)
    |> join(:inner, [c], p in Post, p.id == c.chat_post_id)
    |> join(:inner, [c, p], cl in subquery(Schools.get_school_from_class_subquery(params)), p.class_id == cl.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.student_id not in ^post_students)
    |> distinct([c], c.student_id)
    |> select([c], c.student_id)
    |> Repo.all()

    students = post_students ++ comment_students

    reply_students = from(r in Reply)
    |> join(:inner, [r], c in Comment, r.chat_comment_id == c.id)
    |> join(:inner, [r, c], p in Post, p.id == c.chat_post_id)
    |> join(:inner, [r, c, p], cl in subquery(Schools.get_school_from_class_subquery(params)), p.class_id == cl.class_id)
    |> where([r], fragment("?::date", r.inserted_at) >= ^dates.date_start and fragment("?::date", r.inserted_at) <= ^dates.date_end)
    |> where([r], r.student_id not in ^students)
    |> distinct([r], r.student_id)
    |> select([r], r.student_id)
    |> Repo.all()

    students ++ reply_students
    |> Enum.count()
  end

  defp get_max_chat_activity(dates, params) do
    Chats.get_max_chat_activity(dates, params)
    |> create_max_chat_activity_map()
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

  defp get_chat_post_count(dates, params) do
    from(cp in Post)
    |> join(:inner, [cp], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == cp.class_id)
    |> where([cp], fragment("?::date", cp.inserted_at) >= ^dates.date_start and fragment("?::date", cp.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp get_chat_classes(dates, params) do
    from(cp in subquery(get_unique_chat_class(dates)))
    |> join(:inner, [cp], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == cp.class_id)
    |> Repo.aggregate(:count, :id)
  end

  defp get_unique_chat_class(dates) do
    from(p in Post)
    |> where([p], fragment("?::date", p.inserted_at) >= ^dates.date_start and fragment("?::date", p.inserted_at) <= ^dates.date_end)
    |> distinct([p], p.class_id)
  end

  defp mod_map(dates, params) do
    ModType 
    |> Repo.all()
    |> Enum.map(&build_mod_type_map(&1, dates, params))
  end

  defp build_mod_type_map(type, dates, params) do
    mod_count = get_mod_count(dates, params)
    mod_type_count = get_mod_type_count(type, dates, params)

    Map.new()
    |> Map.put(:type, type.name)
    |> Map.put(:count, mod_type_count)
    |> Map.put(:count_private, get_private_mod_count(type, dates, params))
    |> Map.put(:manual_copies, get_manual_copies(type, dates, params))
    |> Map.put(:manual_dismiss, get_manual_dismisses(type, dates, params))
    |> Map.put(:auto_updates, get_auto_updates(type, dates, params))
    |> Map.put(:percent_mods, calc_mod_percent(mod_count, mod_type_count))
  end

  defp calc_mod_percent(0, _type_count), do: 0
  defp calc_mod_percent(count, type_count), do: (type_count / count) * 100

  defp get_manual_copies(type, dates, params) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, act.assignment_modification_id == m.id)
    |> join(:inner, [m, act], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, act, a], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == a.class_id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == false)
    |> where([m, act], act.is_manual == true and act.is_accepted == true)
    |> where([m, act], fragment("?::date", act.inserted_at) >= ^dates.date_start and fragment("?::date", act.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp get_manual_dismisses(type, dates, params) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, act.assignment_modification_id == m.id)
    |> join(:inner, [m, act], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, act, a], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == a.class_id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == false)
    |> where([m, act], act.is_manual == true and act.is_accepted == false)
    |> where([m, act], fragment("?::date", act.inserted_at) >= ^dates.date_start and fragment("?::date", act.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp get_mod_count(dates, params) do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, a], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == a.class_id)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp get_mod_type_count(type, dates, params) do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, a], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == a.class_id)
    |> where([m], m.assignment_mod_type_id == ^type.id)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp get_auto_updates(type, dates, params) do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, a], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == a.class_id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_auto_update == true)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp get_private_mod_count(type, dates, params) do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, a], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == a.class_id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == true)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp communitites(dates, params) do
    subq = from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)))
    |> where([sc], fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end)
    |> group_by([sc, c, p], sc.class_id)
    |> having([sc, c, p], count(sc.id) >= @community_enrollment)
    |> select([sc], %{count: count(sc.id)})

    from(c in subquery(subq))
    |> select([c], count(c.count))
    |> Repo.one
  end

  defp enrollment_count(dates, params) do
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)))
    |> where([sc], fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end)
    |> select([sc, c, p], count(sc.class_id, :distinct))
    |> Repo.one
  end

  defp classes_multiple_files(dates, params) do
    from(d in Doc)
    |> join(:inner, [d], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == d.class_id)
    |> where([d], fragment("?::date", d.inserted_at) >= ^dates.date_start and fragment("?::date", d.inserted_at) <= ^dates.date_end)
    |> where([d], fragment("exists(select 1 from student_classes sc where sc.class_id = ? and sc.is_dropped = false)", d.class_id))
    |> group_by([d], d.class_id)
    |> having([d], count(d.class_id) > 1)
    |> select([d], count(d.class_id, :distinct))
    |> Repo.all()
    |> Enum.count()
  end

  defp avg_classes(dates, params) do
    from(s in subquery(avg_classes_subquery(dates, params)))
    |> select([s], avg(s.count))
    |> Repo.one()
    |> convert_to_float()
  end

  defp avg_classes_subquery(dates, params) do
    from(s in Student)
    |> join(:left, [s], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)), s.id == sc.student_id and fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end)
    |> group_by([s, sc], sc.student_id)
    |> select([s, sc], %{count: count(sc.student_id)})
  end

  defp assign_count(dates, params) do
    from(a in Assignment)
    |> join(:inner, [a], c in subquery(Schools.get_school_from_class_subquery(params)), a.class_id == c.class_id)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp skoller_assign_count(dates, params) do
    from(a in Assignment)
    |> join(:inner, [a], c in subquery(Schools.get_school_from_class_subquery(params)), a.class_id == c.class_id)
    |> where([a], a.from_mod == false)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp student_assign_count(dates, params) do
    from(a in Assignment)
    |> join(:inner, [a], c in subquery(Schools.get_school_from_class_subquery(params)), a.class_id == c.class_id)
    |> where([a], a.from_mod == true)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp assign_due_date_count(dates, params) do
    from(a in Assignment)
    |> join(:inner, [a], c in subquery(Schools.get_school_from_class_subquery(params)), a.class_id == c.class_id)
    |> where([a], a.from_mod == false)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
    |> where([a], not(is_nil(a.due)))
    |> Repo.aggregate(:count, :id)
  end

  defp assign_per_student(%{completed_class: 0}, _assign), do: 0
  defp assign_per_student(class, assign) do
    Kernel.div(assign.assign_count, class.completed_class) * class.avg_classes
  end

  defp convert_to_float(nil), do: 0.0
  defp convert_to_float(val), do: val |> Decimal.round(2) |> Decimal.to_float()
end