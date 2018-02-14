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

    analytics = Map.new()
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

    render(conn, AnalyticsView, "show.json", analytics: analytics)
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
    from(a in subquery(avg_classes_subquery(dates, params)))
    |> select([a], avg(a.count))
    |> Repo.one()
  end

  defp avg_classes_subquery(dates, %{"school_id" => school_id}) do
    from(s in Student)
    |> join(:left, [s], sc in StudentClass, s.id == sc.student_id and fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end and sc.is_dropped == false)
    |> where([s], s.school_id == ^school_id)
    |> group_by([s], s.id)
    |> select([s], %{count: count(s.id)})
  end
  defp avg_classes_subquery(dates, _params) do
    from(s in Student)
    |> join(:left, [s], sc in StudentClass, s.id == sc.student_id and fragment("?::date", sc.inserted_at) >= ^dates.date_start and fragment("?::date", sc.inserted_at) <= ^dates.date_end and sc.is_dropped == false)
    |> group_by([s], s.id)
    |> select([s], %{count: count(s.id)})
  end
end