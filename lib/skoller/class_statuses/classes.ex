defmodule Skoller.ClassStatuses.Classes do
  @moduledoc """
    Context module for classes and class statuses.
  """

  alias Skoller.Repo
  alias Skoller.Classes.Class
  alias Skoller.ClassStatuses.Status
  alias Skoller.Classes.Schools
  alias Skoller.ClassNotifications
  alias Skoller.Syllabi
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.StudentRequests.StudentRequest
  alias Skoller.Classes

  import Ecto.Query

  require Logger

  @needs_setup_status 1100
  @syllabus_submitted_status 1200
  @needs_student_input_status 1300
  @class_complete_status 1400
  @class_issue_status 1500

  @assignment_lock 200

  @maint_status 999
  @maint_name "Under Maintenance"

  @ghost_name "Ghost"

  def class_in_request?(class_id) do
    class = Classes.get_class_by_id!(class_id)
    class.class_status_id == @class_issue_status
  end

  @doc """
  Returns whether or not a class needs setup.
  """
  def class_needs_setup?(%{class_status_id: @needs_setup_status}), do: true
  def class_needs_setup?(_class), do: false

  @doc """
  A subquery to get classes in the needs setup status.
  """
  def needs_setup_classes_subquery() do
    from(c in Class)
    |> where([c], c.class_status_id == @needs_setup_status)
  end

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
    |> where([c], c.class_status_id == @class_complete_status)
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
    |> where([c], c.class_status_id != @class_complete_status and c.class_status_id > @needs_setup_status)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Takes an old class and a new class, and if the status has just changed to complete, send class complete notification.
  """
  def evaluate_class_completion(old_class, %Class{class_status_id: @class_complete_status} = class) do
    old_class = old_class |> Repo.preload(:class_status)
    case old_class do
      %{class_status: %{is_complete: false}} ->
        Task.start(ClassNotifications, :send_class_complete_notification, [class])
      _ -> nil
    end
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
    |> where([status], status.id == @syllabus_submitted_status)
    |> group_by([status], [status.id, status.name])
    |> select([status, class], %{id: status.id, name: status.name, classes: count(class.id)})
    |> Repo.all()

    admin_status = from(status in Status)
    |> join(:left, [status], class in Class, status.id == class.class_status_id)
    |> where([status], status.id  == @class_issue_status)
    |> group_by([status], [status.id, status.name])
    |> select([status, class], %{id: status.id, name: status.name, classes: count(class.id)})
    |> Repo.all()

    maint = from(class in Class)
    |> where([class], class.is_editable == false)
    |> select([class], %{id: @maint_status, name: @maint_name, classes: count(class.id)})
    |> Repo.all()

    statuses ++ admin_status ++ maint
  end

  @doc """
  Subquery that gets all classes that need a syllabus
  """
  def need_syllabus_status_class_subquery() do
    from(c in Class)
    |> where([c], c.class_status_id == @needs_setup_status)
  end

  @doc """
  Gets class status name from a class or a status.

  ## Returns
  `String`
  """
  def get_class_status(%Class{} = class) do
    class = class |> Repo.preload(:class_status)
    get_status(class)
  end
  def get_class_status(%Status{} = class_status) do
    get_status(%{class_status: class_status})
  end

  @doc """
  Checks if a class should advance status or not.

  ## Checks
  | Event                      | Params                         |
  | -------------------------- | ------------------------------ |
  | Statusless Class           | None                           |
  | Class with no syllabus     | None                           |
  | Doc added to class         | Doc object                     |
  | Change request completed   | Request object                 |
  | Student request completed  | Request object                 |
  | Change request created     | Request object                 |
  | Help request created       | Request object                 |
  | Student request created    | Request object                 |
  | Class unlocked             | List of lock objects           |
  | Class unlocked             | Lock object                    |
  | Student enrolled           | StudentClass object            |

  ## Returns
  `{:ok, Skoller.Classes.Class}` or `{:ok, nil}` or `{:error, map}` or `{:error, Ecto.Changeset}`

  """
  #TODO: Internalize class status updates (remove from SkollerWeb).
  #TODO: Standardize return objects
  # A new class has been added, and it is a class that will never have a syllabus.
  def check_status(class, params) do
    Logger.info("Checking status for class: " <> to_string(class.id) <> " and params:")
    Logger.info(inspect(params))
    cl_check_status(class, params)
  end

  defp cl_check_status(%Class{class_status_id: nil, is_syllabus: false} = class, _params) do
    class |> set_status(@needs_student_input_status)
  end
  defp cl_check_status(%Class{class_status_id: status, is_syllabus: false} = class, _params) when status < @class_complete_status do
    class |> set_status(@needs_student_input_status)
  end
  # A new class has been added.
  defp cl_check_status(%Class{class_status_id: nil} = class, _params) do
    class |> set_status(@needs_setup_status)
  end
  # A syllabus has been added to a class that needs a syllabus.
  defp cl_check_status(%Class{class_status_id: @needs_setup_status} = class, %{doc: %{is_syllabus: true} = doc}) do
    case doc.class_id == class.id do
      true -> class |> set_status(@syllabus_submitted_status)
      false -> {:error, %{class_id: "Class and doc do not match"}}
    end
  end
  # A class in the change status has a change request completed.
  defp cl_check_status(%Class{class_status_id: @class_issue_status} = class, %{change_request: %{is_completed: true} = change_request}) do
    case change_request.class_id == class.id do
      true -> check_req_status(class)
      false -> {:error, %{class_id: "Class and change request do not match"}}
    end
  end
  # A class in the change status has a student request completed.
  defp cl_check_status(%Class{class_status_id: @class_issue_status} = class, %{student_request: %{is_completed: true} = student_request}) do
    case student_request.class_id == class.id do
      true -> check_req_status(class)
      false -> {:error, %{class_id: "Class and student request do not match"}}
    end
  end
  # A class has a change request created.
  defp cl_check_status(%Class{} = class, %{change_request: %{is_completed: false} = change_request}) do
    case change_request.class_id == class.id do
      true -> class |> Repo.preload(:class_status) |> change_status_check()
      false -> {:error, %{class_id: "Class and change request do not match"}}
    end
  end
  defp cl_check_status(%Class{class_status_id: @class_complete_status}, %{unlock: _unlock}), do: {:ok, nil}
  # A class has been fully unlocked. Get the highest lock
  defp cl_check_status(%Class{} = class, %{unlock: unlock}) when is_list(unlock) do
    max_lock = unlock
    |> Enum.filter(&elem(&1, 1).class_id == class.id)
    |> Enum.reduce(0, &case elem(&1, 1).class_lock_section_id > &2 do
        true -> elem(&1, 1).class_lock_section_id
        false -> &2
      end)
    case max_lock do
      @assignment_lock -> class |> set_status(@class_complete_status)
      _ -> {:ok, nil}
    end
  end
  # A student enrolled into a ghost class.
  defp cl_check_status(%Class{is_ghost: true} = class, %{student_class: student_class}) do
    case student_class.class_id == class.id do
      true -> class |> remove_ghost()
      false -> {:error, %{class_id: "Class id enrolled into does not match"}}
    end
  end
  # A student created a student request.
  defp cl_check_status(%Class{} = class, %{student_request: %{is_completed: false} = student_request}) do
    case student_request.class_id == class.id do
      true -> class |> Repo.preload(:class_status) |> set_request_status()
      false -> {:error, %{class_id: "Class id enrolled into does not match"}}
    end
  end
  defp cl_check_status(_class, _params), do: {:ok, nil}

  defp set_status(class, status) do
    Ecto.Changeset.change(class, %{class_status_id: status})
    |> Repo.update()
  end

  #Check to see if there are other incomplete change requests.
  defp check_req_status(%Class{} = class) do
    cr_query = from(cr in ChangeRequest)
    |> where([cr], cr.class_id == ^class.id and cr.is_completed == false)
    |> Repo.all()

    sr_query = from(sr in StudentRequest)
    |> where([sr], sr.class_id == ^class.id and sr.is_completed == false)
    |> Repo.all()

    results = cr_query ++ sr_query

    case results do
      [] -> 
        class |> set_status(@class_complete_status)
      _results -> 
        {:ok, nil}
    end
  end

  defp remove_ghost(%{} = class) do
    class
    |> Ecto.Changeset.change(%{is_ghost: false})
    |> Repo.update()
  end

  #If a change request is attempted when a class is not complete, error
  defp change_status_check(%{class_status: %{is_complete: false}}) do
    {:error, %{error: "Class is incomplete, use Help Request."}}
  end
  defp change_status_check(%{class_status: %{is_complete: true}} = class) do
    class |> set_status(@class_issue_status)
  end

  defp set_request_status(%{class_status: %{is_complete: true}} = class) do
    class |> set_status(@class_issue_status)
  end
  defp set_request_status(%{class_status: %{is_complete: false}} = class) do
    class |> set_status(@needs_student_input_status)
  end

  defp get_status(%{class_status: %{is_complete: false}, is_ghost: true}), do: @ghost_name
  defp get_status(%{class_status: status}), do: status.name
end