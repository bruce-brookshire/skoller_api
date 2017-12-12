defmodule ClassnavapiWeb.Api.V1.SyllabusWorkerController do
  use ClassnavapiWeb, :controller

  alias ClassnavapiWeb.ClassView
  alias Classnavapi.Repo
  alias Classnavapi.Class.Lock
  alias Classnavapi.Class
  alias Classnavapi.Class.Doc
  alias Classnavapi.ClassPeriod

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @syllabus_worker_role 300
  
  @weight_lock 100
  @weight_status 300
  @assignment_lock 200
  @assignment_status 400
  @review_lock 300
  @review_status 500

  plug :verify_role, %{role: @syllabus_worker_role}

  def weights(conn, _params) do
    class = conn |> serve_class(@weight_lock, @weight_status)
    conn |> render(ClassView, "show.json", class: class)
  end

  def assignments(conn, _params) do
    class = conn |> serve_class(@assignment_lock, @assignment_status)
    conn |> render(ClassView, "show.json", class: class)
  end

  def reviews(conn, _params) do
    class = conn |> serve_class(@review_lock, @review_status)
    conn |> render(ClassView, "show.json", class: class)
  end

  defp serve_class(conn, lock_type, status_type) do
    case find_existing_lock(conn, lock_type) do
      [] -> ratios = conn |> get_ratios(status_type)
        workers = get_workers(lock_type)
        class = biggest_difference(ratios, workers) 
                |> get_oldest(conn, status_type, lock_type)
        class |> lock_class(conn, lock_type)
        class
      list -> Repo.get!(Class, List.first(list).class_id)
    end
  end

  defp lock_class(class, %{assigns: %{user: user}}, type) do
    Repo.insert!(%Lock{user_id: user.id, class_lock_section_id: type, class_id: class.id, is_completed: false})
  end

  defp get_oldest(school_id, %{assigns: %{user: user}}, @review_status, @review_lock) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, period], doc in Doc, class.id == doc.class_id)
    |> join(:left, [class, period, doc], lock in Lock, class.id == lock.class_id and (lock.class_lock_section_id == @review_lock or lock.user_id == ^user.id))
    |> where([class], class.class_status_id == @review_status)
    |> where([class, period, doc, lock], doc.is_syllabus == true)
    |> where([class, period, doc, lock], period.school_id == ^school_id)
    |> where([class, period, doc, lock], is_nil(lock.id)) #trying to avoid clashing with manual admin changes
    |> order_by([class, period, doc, lock], asc: doc.inserted_at)
    |> Repo.all()
    |> List.first()
  end

  defp get_oldest(school_id, _conn, status, type) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, period], doc in Doc, class.id == doc.class_id)
    |> join(:left, [class, period, doc], lock in Lock, class.id == lock.class_id and lock.class_lock_section_id == ^type)
    |> where([class], class.class_status_id == ^status)
    |> where([class, period, doc, lock], doc.is_syllabus == true)
    |> where([class, period, doc, lock], period.school_id == ^school_id)
    |> where([class, period, doc, lock], is_nil(lock.id)) #trying to avoid clashing with manual admin changes
    |> order_by([class, period, doc, lock], asc: doc.inserted_at)
    |> Repo.all()
    |> List.first()
  end

  defp biggest_difference(needed, workers) do
    needed = Enum.map(needed, &Map.put(&1, :need, get_difference(&1, workers)))
    max = needed |> Enum.reduce(%{need: 0}, &
      case &1.need > &2.need do
        true -> &1
        false -> &2
      end)
    max.school
  end

  defp get_difference(needed, workers) do
    worker_school = workers |> Enum.find(%{ratio: 0}, & &1.school == needed.school)
    needed.ratio - worker_school.ratio
  end

  defp get_ratios(%{assigns: %{user: user}}, @review_status) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [class, period], lock in Lock, lock.class_id == class.id and lock.user_id == ^user.id)
    |> where([class], class.class_status_id == @review_status)
    |> where([class, period, lock], is_nil(lock.id))
    |> group_by([class, period, lock], period.school_id)
    |> select([class, period, lock], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
    |> get_enum_ratio()
  end

  defp get_ratios(_conn, status) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> where([class], class.class_status_id == ^status)
    |> group_by([class, period], period.school_id)
    |> select([class, period], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
    |> get_enum_ratio()
  end

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