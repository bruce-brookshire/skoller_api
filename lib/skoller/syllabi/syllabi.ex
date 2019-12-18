defmodule Skoller.Syllabi do
  @moduledoc """
  The Syllabi context module.
  """

  alias Skoller.Repo
  alias Skoller.Classes
  alias Skoller.Classes.Class
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Locks.Lock
  alias Skoller.ClassDocs.Doc
  alias Skoller.Locks
  alias Skoller.Locks.Users

  import Ecto.Query

  require Logger

  @syllabus_submitted_status 1200
  @class_period_past_status_id 100

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
  def serve_class(user, lock_type \\ nil, _status_type \\ @syllabus_submitted_status) do
    case Users.get_user_lock(user, lock_type) do
      [] ->
        # TODO, is this needed? get_workers(lock_type) |> get_classes(lock_type, status_type) |> get_one_class()
        class = get_oldest_syllabus()
        class |> lock_class(user, lock_type)
        class

      list ->
        Classes.get_class_by_id!(List.first(list).class_id)
    end
  end

  # Using same logic as above, gets number of all classes that are workable
  def syllabi_class_count() do
    # count = get_classes([], nil, @syllabus_submitted_status) |> get_class_count()

    from(class in Class)
    |> join(:inner, [c], p in ClassPeriod, on: p.id == c.class_period_id)
    |> join(:left, [c, p], l in Lock, on: c.id == l.class_id)
    |> join(:inner, [c, p, l], sc in StudentClass, on: c.id == sc.class_id)
    # Where the class is ready for review and does not have a lock
    |> where([c, p, l, sc], c.class_status_id == @syllabus_submitted_status and is_nil(l.id))
    # Ensure that the class period isnt over yet
    |> where([c, p, l, sc], p.class_period_status_id != @class_period_past_status_id)
    # Remove any double counting, and get the total
    |> select([c, p, l, sc], count(fragment("DISTINCT ?", c.id)))
    |> Repo.one()
  end

  defp get_oldest_syllabus() do
    from(class in Class)
    |> join(:inner, [c], d in Doc, on: d.class_id == c.id)
    |> join(:inner, [c, d], p in ClassPeriod, on: p.id == c.class_period_id)
    |> join(:left, [c, d, p], l in Lock, on: l.class_id == c.id)
    |> where(
      [c, d, p, l],
      c.class_status_id == @syllabus_submitted_status and
        p.class_period_status_id != @class_period_past_status_id and is_nil(l.id)
    )
    |> order_by([c, d, p, l], asc: d.inserted_at)
    |> limit(1)
    |> select([c, d, p, l], c)
    |> Repo.one()
  end

  defp lock_class(nil, _conn, _type), do: nil

  defp lock_class(%{id: id}, user, type) do
    Locks.lock_class(id, user.id, type)
  end
end
