defmodule SkollerWeb.Api.V1.SyllabusWorkerController do
  use SkollerWeb, :controller

  alias SkollerWeb.ClassView
  alias Skoller.Repo
  alias Skoller.Class.Lock
  alias Skoller.Schools.Class
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Classes
  alias Skoller.Locks

  import SkollerWeb.Helpers.AuthPlug
  import Ecto.Query

  require Logger
  
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
      list -> Classes.get_class_by_id!(List.first(list).class_id)
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
    t = Locks.get_oldest_class_by_school(type, status, school_id)
    Logger.info("Get oldest")
    Logger.info(inspect(t))
    t
  end

  defp get_oldest_enrolled(school_id, _conn, status, type) do
    t = Locks.get_oldest_class_by_school(type, status, school_id, [enrolled: true])
    Logger.info("Get oldest enrolled")
    Logger.info(inspect(t))
    t
  end

  # needed structure is [%{count: 544, ratio: 1.0, school_id: 1}] or similar.
  defp biggest_difference(needed, workers) do
    needed = Enum.map(needed, &Map.put(&1, :need, get_difference(&1, workers)))
    max = needed |> Enum.reduce(%{need: 0, school: 0}, &
      case &1.need >= &2.need do
        true -> &1
        false -> &2
      end)
    Logger.info("biggest_difference")
    Logger.info(inspect(max))
    max.school
  end

  defp get_difference(needed, workers) do
    worker_school = workers |> Enum.find(%{ratio: 0}, & &1.school == needed.school)
    needed.ratio - worker_school.ratio
  end

  # select count(p.school_id), p.school_id from classes c inner join class_periods p on 
  # c.class_period_id = p.id inner join schools s on s.id = p.school_id where 
  # c.class_status_id = 300 and s.is_auto_syllabus = true group by p.school_id;
  defp get_ratios(_conn, status) do
    t = Locks.get_processable_classes_by_status(status)
    |> get_enum_ratio()
    Logger.info("get ratios")
    Logger.info(inspect(t))
    t
  end

  defp get_enrolled_ratios(_conn, status) do
    t = Locks.get_processable_classes_by_status(status, [enrolled: true])
    |> get_enum_ratio()
    Logger.info("get_enrolled_ratios")
    Logger.info(inspect(t))
    t
  end

  #select count(p.school_id), p.school_id from public.class_locks l inner join public.classes c 
  #on l.class_id = c.id inner join public.class_periods p on c.class_period_id = p.id where 
  #l.class_lock_section_id = 100 and l.is_completed = false group by p.school_id;
  defp get_workers(type) do
    t = from(lock in Lock)
    |> join(:inner, [lock], class in Class, lock.class_id == class.id)
    |> join(:inner, [lock, class], period in ClassPeriod, period.id == class.class_period_id)
    |> where([lock], lock.class_lock_section_id == ^type and lock.is_completed == false)
    |> group_by([lock, class, period], period.school_id)
    |> select([lock, class, period], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
    |> get_enum_ratio()
    Logger.info("get workers")
    Logger.info(inspect(t))
    t
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