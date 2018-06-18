defmodule Skoller.Syllabi do

  alias Skoller.Repo
  alias Skoller.Classes
  alias Skoller.Schools.Class
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Locks.Lock
  alias Skoller.Class.Doc
  alias Skoller.Schools.School
  alias Skoller.Students
  alias Skoller.Classes.Status
  alias Skoller.Locks
  alias Skoller.Admin.Settings
  alias Skoller.FourDoor.FourDoorOverride

  import Ecto.Query

  require Logger

  @syllabus_processing_setting "is_auto_syllabus"
  
  def serve_class(user, lock_type \\ nil, status_type \\ nil) do
    case find_existing_lock(user, lock_type) do
      [] -> 
        workers = get_workers(lock_type)
        class = workers |> get_class(lock_type, status_type)
        class |> lock_class(user, lock_type)
        class
      list -> Classes.get_class_by_id!(List.first(list).class_id)
    end
  end

  def get_servable_classes_subquery() do
    subq = Settings.get_setting_by_name!(@syllabus_processing_setting).value
    |> generate_servable_schools_subquery()

    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, period], sch in subquery(subq), sch.id == period.school_id)
  end

  defp generate_servable_schools_subquery("true") do
    exclude_list = get_syllabus_overrides_subquery(false)
    |> Repo.all()
    |> Enum.reduce([], & &2 ++ List.wrap(&1.id))

    from(s in School)
    |> where([s], s.id not in ^exclude_list)
  end
  defp generate_servable_schools_subquery("false") do
    get_syllabus_overrides_subquery(true)
  end

  defp get_syllabus_overrides_subquery(val) do
    from(fdo in FourDoorOverride)
    |> where([fdo], fdo.is_auto_syllabus == ^val)
  end

  defp lock_class(%{id: id}, user, nil) do
    Locks.lock_class(id, user.id)
  end
  defp lock_class(%{id: id}, user, type) do
    Repo.insert!(%Lock{user_id: user.id, class_lock_section_id: type, class_id: id, is_completed: false})
  end
  defp lock_class(class, _conn, _type), do: class

  defp get_class(workers, lock_type, status_type) do
    case workers |> find_class(lock_type, status_type, [enrolled: true]) do
      nil -> workers |> find_class(lock_type, status_type, [])
      class -> class
    end
  end

  defp find_class(workers, lock_type, status_type, opts) do
    status_type
    |> get_ratios(opts)
    |> biggest_difference(workers) 
    |> get_oldest(status_type, lock_type, opts)
  end

  defp get_oldest(school_id, status, type, opts) do
    t = get_oldest_class_by_school(type, status, school_id, opts)
    Logger.info("Get oldest")
    Logger.info(inspect(t))
    t
  end

  defp get_oldest_class_by_school(lock_type, class_status, school_id, opts) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, period], doc in subquery(doc_subquery()), class.id == doc.class_id)
    |> lock_join(lock_type)
    |> join(:inner, [class, period, doc, lock], s in Status, class.class_status_id == s.id)
    |> enrolled_classes(opts)
    |> where([class], class.is_editable == true)
    |> where([class, period], period.school_id == ^school_id)
    |> where([class, period, doc, lock], is_nil(lock.id)) #trying to avoid clashing with manual admin changes
    |> where_oldest_status(class_status)
    |> order_by([class, period, doc, lock], asc: doc.inserted_at)
    |> Repo.all()
    |> List.first()
  end

  defp doc_subquery() do
    from(d in Doc)
    |> group_by([d], d.class_id)
    |> select([d], %{inserted_at: min(d.inserted_at), class_id: d.class_id})
  end

  defp get_processable_classes(status_id, opts) do
    from(class in subquery(get_servable_classes_subquery()))
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, peroiod, sch], s in Status, class.class_status_id == s.id)
    |> enrolled_classes(opts)
    |> where([class], class.is_editable == true and class.is_syllabus == true)
    |> where([class], fragment("exists (select 1 from docs where class_id = ?)", class.id))
    |> where_processable_status(status_id)
    |> group_by([class, period], period.school_id)
    |> select([class, period], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
  end

  defp get_ratios(status, opts) do
    t = get_processable_classes(status, opts)
    |> get_enum_ratio()
    Logger.info("get ratios")
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
    |> where([lock], lock.is_completed == false)
    |> where_lock_type(type)
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

  defp find_existing_lock(user, type) do
    from(lock in Lock)
    |> where([lock], lock.user_id == ^user.id and lock.is_completed == false)
    |> where_lock_type(type)
    |> Repo.all()
  end

  defp enrolled_classes(query, []), do: query
  defp enrolled_classes(query, opts) do
    case opts |> List.keytake(:enrolled, 0) |> elem(0) do
      {:enrolled, true} ->
        query |> join(:inner, [class], sc in subquery(Students.get_enrolled_classes_subquery()), sc.class_id == class.id)
      _ -> query
    end
  end

  defp lock_join(query, nil) do
    query
    |> join(:left, [class, period, doc], lock in Lock, class.id == lock.class_id)
  end
  defp lock_join(query, lock_type) do
    query
    |> join(:left, [class, period, doc], lock in Lock, class.id == lock.class_id and lock.class_lock_section_id == ^lock_type)
  end

  defp where_oldest_status(query, nil) do
    query
    |> where([class, period, doc, lock, s], s.is_maintenance == false and s.is_complete == false)
  end
  defp where_oldest_status(query, status_id) do
    query
    |> where([class, period, doc, lock, s], s.id == ^status_id)
  end

  defp where_processable_status(query, nil) do
    query
    |> where([class, period, s], s.is_maintenance == false and s.is_complete == false)
  end
  defp where_processable_status(query, status_id) do
    query
    |> where([class, period, s], s.id == ^status_id)
  end

  defp where_lock_type(query, nil), do: query
  defp where_lock_type(query, type) do
    query |> where([lock], lock.class_lock_section_id == ^type)
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
end