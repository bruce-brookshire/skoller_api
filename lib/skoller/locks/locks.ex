defmodule Skoller.Locks do

  alias Skoller.Repo
  alias Skoller.Schools.Class
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Class.Lock
  alias Skoller.Class.Doc
  alias Skoller.Schools.School
  alias Skoller.Students

  import Ecto.Query

  def get_oldest_class_by_school(lock_type, class_status, school_id, opts \\ []) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, period], doc in subquery(doc_subquery()), class.id == doc.class_id)
    |> join(:left, [class, period, doc], lock in Lock, class.id == lock.class_id and lock.class_lock_section_id == ^lock_type)
    |> enrolled_classes(opts)
    |> where([class], class.class_status_id == ^class_status and class.is_editable == true)
    |> where([class, period], period.school_id == ^school_id)
    |> where([class, period, doc, lock], is_nil(lock.id)) #trying to avoid clashing with manual admin changes
    |> order_by([class, period, doc, lock], asc: doc.inserted_at)
    |> Repo.all()
    |> List.first()
  end

  def get_processable_classes_by_status(status_id, opts \\ []) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:inner, [class, period], sch in School, sch.id == period.school_id)
    |> enrolled_classes(opts)
    |> where([class], class.class_status_id == ^status_id and class.is_editable == true and class.is_syllabus == true)
    |> where([class, period, sch], sch.is_auto_syllabus == true)
    |> where([class, period, sc, sch], fragment("exists (select 1 from docs where class_id = ?)", class.id))
    |> group_by([class, period, sch], period.school_id)
    |> select([class, period, sch], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
  end

  def get_workers(type) do
    from(lock in Lock)
    |> join(:inner, [lock], class in Class, lock.class_id == class.id)
    |> join(:inner, [lock, class], period in ClassPeriod, period.id == class.class_period_id)
    |> where([lock], lock.class_lock_section_id == ^type and lock.is_completed == false)
    |> group_by([lock, class, period], period.school_id)
    |> select([lock, class, period], %{count: count(period.school_id), school: period.school_id})
    |> Repo.all()
  end

  defp doc_subquery() do
    from(d in Doc)
    |> group_by([d], d.class_id)
    |> select([d], %{inserted_at: min(d.inserted_at), class_id: d.class_id})
  end

  defp enrolled_classes(query, []), do: query
  defp enrolled_classes(query, opts) do
    case opts |> List.keytake(:enrolled, 0) |> elem(0) do
      {:enrolled, true} ->
        query |> join(:inner, [class], sc in subquery(Students.get_enrolled_classes_subquery()), sc.class_id == class.id)
      _ -> query
    end
  end
end