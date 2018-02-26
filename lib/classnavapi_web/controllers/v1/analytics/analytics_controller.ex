defmodule ClassnavapiWeb.Api.V1.Analytics.AnalyticsController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Class
  alias Classnavapi.ClassPeriod
  alias Classnavapi.Class.StudentClass
  alias ClassnavapiWeb.AnalyticsView
  alias Classnavapi.Class.Lock
  alias Classnavapi.User
  alias Classnavapi.UserRole
  alias Classnavapi.Class.Doc
  alias Classnavapi.Student
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Assignment.Mod.Type, as: ModType
  alias Classnavapi.Assignment.Mod
  alias Classnavapi.Assignment.Mod.Action

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @student_role 100
  @admin_role 200

  @completed_status 700
  @in_review_status 300

  @diy_complete_lock 200

  @community_enrollment 2
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, params) do
    dates = Map.new 
            |> Map.put(:date_start, Date.from_iso8601!(params["date_start"]))
            |> Map.put(:date_end, Date.from_iso8601!(params["date_end"]))

    completed_classes = completed_class(dates, params)
    completed_by_diy = completed_by_diy(dates, params)

    class = Map.new()
    |> Map.put(:class_count, class_count(dates, params))
    |> Map.put(:enrollment, enrollment_count(dates, params))
    |> Map.put(:completed_class, completed_classes)
    |> Map.put(:communitites, communitites(dates, params))
    |> Map.put(:class_in_review, class_in_review(dates, params))
    |> Map.put(:completed_by_diy, completed_by_diy)
    |> Map.put(:completed_by_skoller, completed_classes - completed_by_diy)
    |> Map.put(:class_syllabus_count, syllabus_count(dates, params))
    |> Map.put(:classes_multiple_files, classes_multiple_files(dates, params))
    |> Map.put(:student_created_classes, student_created_count(dates, params))
    |> Map.put(:avg_classes, avg_classes(dates, params))

    assignment = Map.new()
    |> Map.put(:assign_count, assign_count(dates, params))
    |> Map.put(:assign_due_date_count, assign_due_date_count(dates, params))

    assignment = assignment
    |> Map.put(:assign_per_student, assign_per_student(class, assignment))

    analytics = Map.new()
    |> Map.put(:class, class)
    |> Map.put(:assignment, assignment)
    |> Map.put(:mod, mod_map(dates, params))

    render(conn, AnalyticsView, "show.json", analytics: analytics)
  end

  defp mod_map(dates, params) do
    ModType 
    |> Repo.all()
    |> Enum.map(&build_mod_type_map(&1, dates, params))
  end

  defp build_mod_type_map(type, dates, params) do
    Map.new()
    |> Map.put(:type, type.name)
    |> Map.put(:count, get_mod_count(type, dates, params))
    |> Map.put(:count_private, get_private_mod_count(type, dates, params))
    |> Map.put(:manual_copies, get_manual_copies(type, dates, params))
    |> Map.put(:manual_dismiss, get_manual_dismisses(type, dates, params))
    |> Map.put(:auto_updates, get_auto_updates(type, dates, params))
  end

  defp get_manual_copies(type, dates, %{"school_id" => school_id}) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, act.assignment_modification_id == m.id)
    |> join(:inner, [m, act], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, act, a], c in Class, c.id == a.class_id)
    |> join(:inner, [m, act, a, c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == false)
    |> where([m, act], act.is_manual == true and act.is_accepted == true)
    |> where([m, a, c, p], p.school_id == ^school_id)
    |> where([m, act], fragment("?::date", act.inserted_at) >= ^dates.date_start and fragment("?::date", act.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end
  defp get_manual_copies(type, dates, _params) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, act.assignment_modification_id == m.id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == false)
    |> where([m, act], fragment("?::date", act.inserted_at) >= ^dates.date_start and fragment("?::date", act.inserted_at) <= ^dates.date_end)
    |> where([m, act], act.is_manual == true and act.is_accepted == true)
    |> Repo.aggregate(:count, :id)
  end

  defp get_manual_dismisses(type, dates, %{"school_id" => school_id}) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, act.assignment_modification_id == m.id)
    |> join(:inner, [m, act], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, act, a], c in Class, c.id == a.class_id)
    |> join(:inner, [m, act, a, c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == false)
    |> where([m, act], act.is_manual == true and act.is_accepted == false)
    |> where([m, a, c, p], p.school_id == ^school_id)
    |> where([m, act], fragment("?::date", act.inserted_at) >= ^dates.date_start and fragment("?::date", act.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end
  defp get_manual_dismisses(type, dates, _params) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, act.assignment_modification_id == m.id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == false)
    |> where([m, act], fragment("?::date", act.inserted_at) >= ^dates.date_start and fragment("?::date", act.inserted_at) <= ^dates.date_end)
    |> where([m, act], act.is_manual == true and act.is_accepted == false)
    |> Repo.aggregate(:count, :id)
  end

  defp get_mod_count(type, dates, %{"school_id" => school_id}) do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, a], c in Class, c.id == a.class_id)
    |> join(:inner, [m, a, c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([m], m.assignment_mod_type_id == ^type.id)
    |> where([m, a, c, p], p.school_id == ^school_id)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end
  defp get_mod_count(type, dates, _params) do
    from(m in Mod)
    |> where([m], m.assignment_mod_type_id == ^type.id)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp get_auto_updates(type, dates, %{"school_id" => school_id}) do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, a], c in Class, c.id == a.class_id)
    |> join(:inner, [m, a, c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_auto_update == true)
    |> where([m, a, c, p], p.school_id == ^school_id)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end
  defp get_auto_updates(type, dates, _params) do
    from(m in Mod)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_auto_update == true)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp get_private_mod_count(type, dates, %{"school_id" => school_id}) do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, a], c in Class, c.id == a.class_id)
    |> join(:inner, [m, a, c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == true)
    |> where([m, a, c, p], p.school_id == ^school_id)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end
  defp get_private_mod_count(type, dates, _params) do
    from(m in Mod)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == true)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp communitites(dates, %{"school_id" => school_id}) do
    subq = from(sc in StudentClass)
    |> join(:inner, [sc], c in Class, c.id == sc.class_id)
    |> join(:inner, [sc, c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([sc, c, p], p.school_id == ^school_id)
    |> where([sc], sc.is_dropped == false)
    |> where([sc], fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end)
    |> group_by([sc, c, p], sc.class_id)
    |> having([sc, c, p], count(sc.id) >= @community_enrollment)
    |> select([sc], %{count: count(sc.id)})

    from(c in subquery(subq))
    |> select([c], count(c.count))
    |> Repo.one
  end
  defp communitites(dates, _params) do
    subq = from(sc in StudentClass)
    |> where([sc], fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end)
    |> where([sc], sc.is_dropped == false)
    |> group_by([sc], sc.class_id)
    |> having([sc], count(sc.id) >= @community_enrollment)
    |> select([sc], %{count: count(sc.id)})

    from(c in subquery(subq))
    |> select([c], count(c.count))
    |> Repo.one
  end

  defp completed_class(dates, %{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([c, p], p.school_id == ^school_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.class_status_id == @completed_status)
    |> Repo.aggregate(:count, :id)
  end
  defp completed_class(dates, _params) do
    from(c in Class)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.class_status_id == @completed_status)
    |> Repo.aggregate(:count, :id)
  end

  defp class_in_review(dates, %{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([c, p], p.school_id == ^school_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.class_status_id != @completed_status and c.class_status_id >= @in_review_status)
    |> Repo.aggregate(:count, :id)
  end
  defp class_in_review(dates, _params) do
    from(c in Class)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.class_status_id != @completed_status and c.class_status_id >= @in_review_status)
    |> Repo.aggregate(:count, :id)
  end

  defp enrollment_count(dates, %{"school_id" => school_id}) do
    from(sc in StudentClass)
    |> join(:inner, [sc], c in Class, c.id == sc.class_id)
    |> join(:inner, [sc, c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([sc, c, p], p.school_id == ^school_id)
    |> where([sc], sc.is_dropped == false)
    |> where([sc], fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end)
    |> select([sc, c, p], count(sc.class_id, :distinct))
    |> Repo.one
  end
  defp enrollment_count(dates, _params) do
    from(sc in StudentClass)
    |> where([sc], fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end)
    |> where([sc], sc.is_dropped == false)
    |> select([sc], count(sc.class_id, :distinct))
    |> Repo.one
  end

  defp class_count(dates, %{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([c, p], p.school_id == ^school_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end
  defp class_count(dates, _params) do
    from(c in Class)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp student_created_count(dates, %{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([c, p], p.school_id == ^school_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.is_student_created == true)
    |> Repo.aggregate(:count, :id)
  end
  defp student_created_count(dates, _params) do
    from(c in Class)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.is_student_created == true)
    |> Repo.aggregate(:count, :id)
  end

  defp syllabus_count(dates, %{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> join(:inner, [c, p], d in subquery(syllabus_subquery()), d.class_id == c.id)
    |> where([c, p], p.school_id == ^school_id)
    |> where([c, d], fragment("?::date", d.inserted_at) >= ^dates.date_start and fragment("?::date", d.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end
  defp syllabus_count(dates, _params) do
    from(c in Class)
    |> join(:inner, [c], d in subquery(syllabus_subquery()), d.class_id == c.id)
    |> where([c, d], fragment("?::date", d.inserted_at) >= ^dates.date_start and fragment("?::date", d.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp syllabus_subquery() do
    from(d in Doc)
    |> where([d], d.is_syllabus == true)
    |> distinct([d], d.class_id)
    |> order_by([d], asc: d.inserted_at)
  end

  defp completed_by_diy(dates, %{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> join(:inner, [c, p], l in Lock, l.class_id == c.id and l.class_lock_section_id == @diy_complete_lock and l.is_completed == true)
    |> join(:inner, [c, p, l], u in User, u.id == l.user_id)
    |> join(:inner, [c, p, l, u], r in UserRole, r.user_id == u.id)
    |> where([c, p, l, u, r], r.role_id == @student_role)
    |> where([c, p], p.school_id == ^school_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end
  defp completed_by_diy(dates, _params) do
    from(c in Class)
    |> join(:inner, [c], l in Lock, l.class_id == c.id and l.class_lock_section_id == @diy_complete_lock and l.is_completed == true)
    |> join(:inner, [c, l], u in User, u.id == l.user_id)
    |> join(:inner, [c, l, u], r in UserRole, r.user_id == u.id)
    |> where([c, l, u, r], r.role_id == @student_role)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp classes_multiple_files(dates, %{"school_id" => school_id}) do
    from(d in Doc)
    |> join(:inner, [d], c in Class, c.id == d.class_id)
    |> join(:inner, [d, c], p in ClassPeriod, p.id == c.class_period_id)
    |> where([d], fragment("?::date", d.inserted_at) >= ^dates.date_start and fragment("?::date", d.inserted_at) <= ^dates.date_end)
    |> where([d, c, p], p.school_id == ^school_id)
    |> group_by([d], d.class_id)
    |> having([d], count(d.class_id) > 1)
    |> select([d], count(d.class_id, :distinct))
    |> Repo.all()
    |> Enum.count()
  end
  defp classes_multiple_files(dates, _params) do
    from(d in Doc)
    |> where([d], fragment("?::date", d.inserted_at) >= ^dates.date_start and fragment("?::date", d.inserted_at) <= ^dates.date_end)
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

  defp avg_classes_subquery(dates, %{"school_id" => school_id}) do
    from(s in Student)
    |> join(:left, [s], sc in StudentClass, s.id == sc.student_id and fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end and sc.is_dropped == false)
    |> where([s], s.school_id == ^school_id)
    |> group_by([s, sc], sc.student_id)
    |> select([s, sc], %{count: count(sc.student_id)})
  end
  defp avg_classes_subquery(dates, _params) do
    from(s in Student)
    |> join(:left, [s], sc in StudentClass, s.id == sc.student_id and fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end and sc.is_dropped == false)
    |> group_by([s, sc], sc.student_id)
    |> select([s, sc], %{count: count(sc.student_id)})
  end

  defp assign_count(dates, %{"school_id" => school_id}) do
    from(a in Assignment)
    |> join(:inner, [a], c in Class, a.class_id == c.id)
    |> join(:inner, [a, c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([a, c, p], p.school_id == ^school_id)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end
  defp assign_count(dates, _params) do
    from(a in Assignment)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp assign_due_date_count(dates, %{"school_id" => school_id}) do
    from(a in Assignment)
    |> join(:inner, [a], c in Class, a.class_id == c.id)
    |> join(:inner, [a, c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([a, c, p], p.school_id == ^school_id)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
    |> where([a], not(is_nil(a.due)))
    |> Repo.aggregate(:count, :id)
  end
  defp assign_due_date_count(dates, _params) do
    from(a in Assignment)
    |> where([a], fragment("?::date", a.inserted_at) >= ^dates.date_start and fragment("?::date", a.inserted_at) <= ^dates.date_end)
    |> where([a], not(is_nil(a.due)))
    |> Repo.aggregate(:count, :id)
  end

  defp assign_per_student(%{completed_class: 0}, _assign), do: 0
  defp assign_per_student(class, assign) do
    Kernel.div(assign.assign_count, class.completed_class) * class.avg_classes
  end

  defp convert_to_float(nil), do: 0.0
  defp convert_to_float(val), do: val |> Decimal.to_float()
end