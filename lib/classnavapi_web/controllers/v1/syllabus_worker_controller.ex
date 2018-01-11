defmodule ClassnavapiWeb.Api.V1.SyllabusWorkerController do
  use ClassnavapiWeb, :controller

  alias ClassnavapiWeb.ClassView
  alias Classnavapi.Repo
  alias Classnavapi.Class.Lock
  alias Classnavapi.Class
  alias Classnavapi.Class.Doc
  alias Classnavapi.ClassPeriod
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.School

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @admin_role 200
  @syllabus_worker_role 300
  
  @weight_lock 100
  @weight_status 300
  @assignment_lock 200
  @assignment_status 400
  @review_lock 300
  @review_status 500

  plug :verify_role, %{roles: [@syllabus_worker_role, @admin_role]}

  def weights(conn, _params) do
    class = conn |> serve_class(@weight_lock, @weight_status)
    case class do
      nil ->  conn |> send_resp(204, "")
      class -> conn |> render(ClassView, "show.json", class: class)
    end
  end

  def assignments(conn, _params) do
    class = conn |> serve_class(@assignment_lock, @assignment_status)
    case class do
      nil ->  conn |> send_resp(204, "")
      class -> conn |> render(ClassView, "show.json", class: class)
    end
  end

  def reviews(conn, _params) do
    class = conn |> serve_class(@review_lock, @review_status)
    case class do
      nil ->  conn |> send_resp(204, "")
      class -> conn |> render(ClassView, "show.json", class: class)
    end
  end

  defp serve_class(conn, lock_type, status_type) do
    case find_existing_lock(conn, lock_type) do
      [] -> 
        workers = get_workers(lock_type)
        class = workers |> get_class(conn, lock_type, status_type)
        class |> lock_class(conn, lock_type)
        class
      list -> Repo.get!(Class, List.first(list).class_id)
    end
  end

  defp get_class(workers, conn, lock_type, status_type) do
    case workers |> get_enrolled_class(conn, lock_type, status_type) do
      nil -> workers |> get_unenrolled_class(conn, lock_type, status_type)
      class -> class
    end
  end

  defp get_enrolled_class(workers, conn, lock_type, status_type) do
    conn 
    |> get_enrolled_ratios(status_type)
    |> biggest_difference(workers) 
    |> get_oldest_enrolled(conn, status_type, lock_type)
  end

  defp get_unenrolled_class(workers, conn, lock_type, status_type) do
    conn 
    |> get_ratios(status_type)
    |> biggest_difference(workers) 
    |> get_oldest(conn, status_type, lock_type)
  end

  defp lock_class(%{id: id}, %{assigns: %{user: user}}, type) do
    Repo.insert!(%Lock{user_id: user.id, class_lock_section_id: type, class_id: id, is_completed: false})
  end
  defp lock_class(class, _conn, _type), do: class

  defp get_oldest(school_id, _conn, status, type) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, period], doc in Doc, class.id == doc.class_id)
    |> join(:left, [class, period, doc], lock in Lock, class.id == lock.class_id and lock.class_lock_section_id == ^type)
    |> where([class], class.class_status_id == ^status and class.is_editable = true)
    |> where([class, period, doc, lock], doc.is_syllabus == true)
    |> where([class, period, doc, lock], period.school_id == ^school_id)
    |> where([class, period, doc, lock], is_nil(lock.id)) #trying to avoid clashing with manual admin changes
    |> order_by([class, period, doc, lock], asc: doc.inserted_at)
    |> Repo.all()
    |> List.first()
  end

  defp get_oldest_enrolled(school_id, _conn, status, type) do
    from(class in Class)
    |> join(:inner, [class], sc in subquery(enrolled_subquery()), sc.class_id == class.id)
    |> join(:inner, [class, sc], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, sc, period], doc in Doc, class.id == doc.class_id)
    |> join(:left, [class, sc, period, doc], lock in Lock, class.id == lock.class_id and lock.class_lock_section_id == ^type)
    |> where([class], class.class_status_id == ^status and class.is_editable = true)
    |> where([class, sc, period, doc, lock], doc.is_syllabus == true)
    |> where([class, sc, period, doc, lock], period.school_id == ^school_id)
    |> where([class, sc, period, doc, lock], is_nil(lock.id)) #trying to avoid clashing with manual admin changes
    |> order_by([class, sc, period, doc, lock], asc: doc.inserted_at)
    |> Repo.all()
    |> List.first()
  end

  # needed structure is [%{count: 544, ratio: 1.0, school_id: 1}] or similar.
  defp biggest_difference(needed, workers) do
    needed = Enum.map(needed, &Map.put(&1, :need, get_difference(&1, workers)))
    max = needed |> Enum.reduce(%{need: 0, school: 0}, &
      case &1.need >= &2.need do
        true -> &1
        false -> &2
      end)
    max.school
  end

  defp get_difference(needed, workers) do
    worker_school = workers |> Enum.find(%{ratio: 0}, & &1.school == needed.school)
    needed.ratio - worker_school.ratio
  end

  #select count(p.school_id), p.school_id from classes c inner join class_periods p on 
  #c.class_period_id = p.id inner join schools s on s.id = p.school_id where 
  #c.class_status_id = 300 and s.is_auto_syllabus = true group by p.school_id;
  defp get_ratios(_conn, status) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, period], sch in School, sch.id == period.school_id)
    |> where([class], class.class_status_id == ^status and class.is_editable = true)
    |> where([class, period, sch], sch.is_auto_syllabus == true)
    |> group_by([class, period, sch], period.school_id)
    |> select([class, period, sch], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
    |> get_enum_ratio()
  end

  defp get_enrolled_ratios(_conn, status) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, period], sc in subquery(enrolled_subquery()), class.id == sc.class_id)
    |> join(:inner, [class, period, sc], sch in School, sch.id == period.school_id)
    |> where([class], class.class_status_id == ^status and class.is_editable = true)
    |> where([class, period, sc, sch], sch.is_auto_syllabus == true)
    |> group_by([class, period, sc, sch], period.school_id)
    |> select([class, period, sc, sch], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
    |> get_enum_ratio()
  end

  defp enrolled_subquery() do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
    |> distinct([sc], sc.class_id)
  end

  #select count(p.school_id), p.school_id from public.class_locks l inner join public.classes c 
  #on l.class_id = c.id inner join public.class_periods p on c.class_period_id = p.id where 
  #l.class_lock_section_id = 100 and l.is_completed = false group by p.school_id;
  defp get_workers(type) do
    from(lock in Lock)
    |> join(:inner, [lock], class in Class, lock.class_id == class.id)
    |> join(:inner, [lock, class], period in ClassPeriod, period.id == class.class_period_id)
    |> where([lock], lock.class_lock_section_id == ^type and lock.is_completed == false)
    |> group_by([lock, class, period], period.school_id)
    |> select([lock, class, period], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
    |> get_enum_ratio()
  end

  defp get_enum_ratio(enumerable) do
    sum = enumerable |> Enum.reduce(0, & &1.count + &2)
    
    enumerable |> Enum.map(&Map.put(&1, :ratio, &1.count / sum))
  end

  defp find_existing_lock(%{assigns: %{user: user}}, type) do
    from(lock in Lock)
    |> where([lock], lock.user_id == ^user.id and lock.is_completed == false and lock.class_lock_section_id == ^type)
    |> Repo.all()
  end
end