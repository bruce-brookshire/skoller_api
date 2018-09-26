defmodule Skoller.Classes.ClassStatuses do
  @moduledoc """
    Context module for classes and class statuses.
  """

  alias Skoller.Repo
  alias Skoller.Classes.Class
  alias Skoller.ClassStatuses.Status
  alias Skoller.Classes.Schools
  alias Skoller.ClassNotifications
  alias Skoller.Syllabi

  import Ecto.Query

  @weight_status 300
  @assignment_status 400
  @review_status 500
  @help_status 600
  @completed_status 700
  @change_status 800

  @in_review_status 300

  @maint_status 999
  @maint_name "Under Maintenance"

  @doc """
  Gets a count of completed classes created between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  
  """
  def get_completed_class_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^date_start and fragment("?::date", c.inserted_at) <= ^date_end)
    |> where([c], c.class_status_id == @completed_status)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a count of classes in review (has syllabus but not complete) created between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  
  """
  def get_class_in_review_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^date_start and fragment("?::date", c.inserted_at) <= ^date_end)
    |> where([c], c.class_status_id != @completed_status and c.class_status_id >= @in_review_status)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Takes an old class and a new class, and if the status has just changed to complete, send class complete notification.
  """
  def evaluate_class_completion(old_class, new_class)
  def evaluate_class_completion(%Class{class_status_id: @completed_status}, %Class{class_status_id: @completed_status}), do: nil
  def evaluate_class_completion(%Class{class_status_id: @change_status}, %Class{class_status_id: @completed_status}), do: nil
  def evaluate_class_completion(%Class{class_status_id: _old_status}, %Class{class_status_id: @completed_status} = class) do
    Task.start(ClassNotifications, :send_class_complete_notification, [class])
  end
  def evaluate_class_completion(_old_class, _class), do: nil

  @doc """
  Gets a count of all status and the count of classes in them.

  ## Behavior
  The syllabus worker statuses are only going to return syllabus workable schools.

  ## Returns
  `[%{id: Skoller.ClassStatuses.Status.id, name: Skoller.ClassStatuses.Status.name, classes: Integer}]` or `nil`
  """
  def get_class_status_counts() do
    statuses = from(status in Status)
    |> join(:left, [status], class in subquery(Syllabi.get_servable_classes_subquery()), status.id == class.class_status_id)
    |> where([status], status.id in [@weight_status, @assignment_status, @review_status])
    |> group_by([status], [status.id, status.name, status.is_complete])
    |> select([status, class], %{id: status.id, name: status.name, classes: count(class.id)})
    |> Repo.all()

    admin_status = from(status in Status)
    |> join(:left, [status], class in Class, status.id == class.class_status_id)
    |> where([status], status.id in [@help_status, @change_status])
    |> group_by([status], [status.id, status.name, status.is_complete])
    |> select([status, class], %{id: status.id, name: status.name, classes: count(class.id)})
    |> Repo.all()

    maint = from(class in Class)
    |> where([class], class.is_editable == false)
    |> select([class], %{id: @maint_status, name: @maint_name, classes: count(class.id)})
    |> Repo.all()

    statuses ++ admin_status ++ maint
  end
end