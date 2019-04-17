defmodule Skoller.Syllabi do
  @moduledoc """
  The Syllabi context module.
  """

  alias Skoller.Repo
  alias Skoller.Classes
  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Locks.Lock
  alias Skoller.ClassDocs.Doc
  alias Skoller.Schools.School
  alias Skoller.EnrolledStudents
  alias Skoller.ClassStatuses.Status
  alias Skoller.Locks
  alias Skoller.Settings
  alias Skoller.FourDoor.FourDoorOverride
  alias Skoller.Locks.Users

  import Ecto.Query

  require Logger

  @syllabus_processing_setting "is_auto_syllabus"

  @syllabus_submitted_status 1200
  
  @doc """
  Serves a class to a syllabus worker.

  ## Notes
   * The class will be the oldest enrolled class in the most underserved school,
   followed by the oldest class in the most underserved school.
   * The class will be locked for the worker.
   * If the worker has a lock already, that will be served to them until abandoned.

  ## Params
   * The default is to serve a class regardless of status or lock.
   * To lock (and find) classes based on a single status, pass in `lock_type` and `status_type`
  """
  def serve_class(user, lock_type \\ nil, status_type \\ @syllabus_submitted_status) do
    case Users.get_user_lock(user, lock_type) do
      [] -> 
        class = get_workers(lock_type) |> get_classes(lock_type, status_type) |> get_one_class()
        class |> lock_class(user, lock_type)
        class
      list -> Classes.get_class_by_id!(List.first(list).class_id)
    end
  end
  # Using same logic as above, gets number of all classes that are workable
  def syllabi_class_count() do
    count = get_classes([], nil, @syllabus_submitted_status) |> get_class_count()
  end

  @doc """
  Subquery that gets a list of classes where syllabus workers are allowed to work on them.
  """
  def get_servable_classes_subquery() do
    subq = Settings.get_setting_by_name!(@syllabus_processing_setting).value
    |> generate_servable_schools_subquery()

    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, on: class.class_period_id == period.id)
    |> join(:inner, [class, period], sch in subquery(subq), on: sch.id == period.school_id)
  end

  # This function takes in the current admin setting as the parameter.
  # If it is true, it needs to find a list of schools overriding it to false.
  # If it is false, it gets a list of schools overriding it to true.
  defp generate_servable_schools_subquery("true") do
    exclude_list = get_syllabus_overrides_subquery(false)
    |> Repo.all()
    |> Enum.reduce([], & &2 ++ List.wrap(&1.school_id))

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

  defp lock_class(nil, _conn, _type), do: nil
  defp lock_class(%{id: id}, user, type) do
    Locks.lock_class(id, user.id, type)
  end

  # Tries to find an enrolled class, then a non enrolled class, of the lock and status type.
  defp get_classes(workers, lock_type, status_type) do
    case workers |> find_classes(lock_type, status_type, [enrolled: true]) do
      nil -> workers |> find_classes(lock_type, status_type, [])
      class -> class
    end
  end

  # This gets a ratio of workers to avaliable classes at each school, finds the school with the most need,
  # and then gets the oldest class at the school.
  defp find_classes(workers, lock_type, status_type, opts) do
    status_type
    |> get_ratios(opts)
    |> biggest_difference(workers) 
    |> get_oldest(status_type, lock_type, opts)
  end

  # Gets the oldest class at a school with the params below.
  defp get_oldest(school_id, status, type, opts) do
    t = get_oldest_classes_by_school(type, status, school_id, opts)
    Logger.info("Get oldest")
    Logger.info(inspect(t))
    t
  end

  # This gets the oldest class at a school.
  # The class must have a doc, must not be locked, must be editable.
  defp get_oldest_classes_by_school(lock_type, class_status, school_id, opts) do
    from(class in Class)
    |> join(:inner, [class], doc in subquery(doc_subquery(school_id)), on: class.id == doc.class_id)
    |> lock_join(lock_type)
    |> join(:inner, [class], s in Status, on: class.class_status_id == s.id)
    |> enrolled_classes(opts)
    |> where([class], class.is_editable == true)
    |> where([class, doc, lock], is_nil(lock.id)) #trying to avoid clashing with manual admin changes
    |> where_oldest_status(class_status)
  end

  defp doc_subquery(school_id) do
    from(d in Doc)
    |> join(:inner, [d], c in Class, on: c.id == d.class_id)
    |> join(:inner, [d, class], period in ClassPeriod, on: class.class_period_id == period.id)
    |> where([d, class, period], period.school_id == ^school_id)
    |> group_by([d], [d.class_id, d.inserted_at])
    |> order_by([d], asc: d.inserted_at)
    |> select([d], %{inserted_at: d.inserted_at, class_id: d.class_id})
  end

    # Helper methods to cap the query for syllabi classes
    defp get_one_class(query) do
      query
      |> order_by([class, doc], asc: doc.inserted_at)
      |> limit(1)
      |> Repo.one()
    end
    defp get_class_count(query) do
      query
      |> select([class], count(class.id))
      |> Repo.one()
    end

  # Gets a list of classes that are valid for a syllabus worker to work.
  # Must have a doc, be editable, and be set to have a syllabus.
  defp get_processable_classes(status_id, opts) do
    from(class in subquery(get_servable_classes_subquery()))
    |> join(:inner, [class], period in ClassPeriod, on: class.class_period_id == period.id)
    |> join(:inner, [class, peroiod, sch], s in Status, on: class.class_status_id == s.id)
    |> enrolled_classes(opts)
    |> where([class], class.is_editable == true and class.is_syllabus == true)
    |> where([class], fragment("exists (select 1 from docs where class_id = ?)", class.id))
    |> where_processable_status(status_id)
    |> group_by([class, period], period.school_id)
    |> select([class, period], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
  end

  # Gets a ratio of school_classes : total_classes for all schools.
  defp get_ratios(status, opts) do
    t = get_processable_classes(status, opts)
    |> get_enum_ratio()
    Logger.info("get ratios")
    Logger.info(inspect(t))
    t
  end

  # Gets a ratio of currently working users per school over total workers.
  defp get_workers(type) do
    t = from(lock in subquery(unique_class_locks()))
    |> join(:inner, [lock], class in Class, on: lock.class_id == class.id)
    |> join(:inner, [lock, class], period in ClassPeriod, on: period.id == class.class_period_id)
    |> where_lock_type(type)
    |> group_by([lock, class, period], period.school_id)
    |> select([lock, class, period], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
    |> get_enum_ratio()
    Logger.info("get workers")
    Logger.info(inspect(t))
    t
  end

  defp unique_class_locks() do
    from(lock in Lock)
    |> distinct([lock], lock.user_id)
  end

  # Takes in an enum where each element has a count, and returns
  # the enum with a :ratio field.
  defp get_enum_ratio(enumerable) do
    sum = enumerable |> Enum.reduce(0, & &1.count + &2)
    
    enumerable |> Enum.map(&Map.put(&1, :ratio, &1.count / sum))
  end

  # If opts are passed in with enrolled: true, then add a join to only get enrolled classes.
  defp enrolled_classes(query, []), do: query
  defp enrolled_classes(query, opts) do
    case opts |> List.keytake(:enrolled, 0) |> elem(0) do
      {:enrolled, true} ->
        query |> join(:inner, [class], sc in subquery(EnrolledStudents.get_enrolled_classes_subquery()), on: sc.class_id == class.id)
      _ -> query
    end
  end

  defp lock_join(query, nil) do
    query
    |> join(:left, [class, doc], lock in Lock, on: class.id == lock.class_id)
  end
  defp lock_join(query, lock_type) do
    query
    |> join(:left, [class, doc], lock in Lock, on: class.id == lock.class_id and lock.class_lock_section_id == ^lock_type)
  end

  defp where_oldest_status(query, nil) do
    query
    |> where([class, doc, lock, s], s.is_maintenance == false and s.is_complete == false)
  end
  defp where_oldest_status(query, status_id) do
    query
    |> where([class, doc, lock, s], s.id == ^status_id)
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

  # Finds the biggest need in schools.
  defp biggest_difference(needed, workers) do
    max = needed
    |> Enum.map(&Map.put(&1, :need, get_difference(&1, workers)))
    |> Enum.reduce(%{need: 0, school: 0}, &
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