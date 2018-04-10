defmodule Skoller.Classes do

  alias Skoller.Repo
  alias Skoller.Schools.Class
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Class.Status
  alias Skoller.Class.Doc
  alias Skoller.Class.Lock
  alias Skoller.Users.User
  alias Skoller.UserRole
  alias Skoller.Schools
  alias Skoller.Universities
  alias Skoller.HighSchools
  alias SkollerWeb.Helpers.NotificationHelper
  alias Skoller.Schools.School
  alias Skoller.Professor
  alias Skoller.Class.ChangeRequest
  alias Skoller.Class.StudentRequest

  import Ecto.Query

  @student_role 100

  @needs_syllabus_status 200
  @weight_status 300
  @assignment_status 400
  @review_status 500
  @help_status 600
  @completed_status 700
  @change_status 800

  @weight_lock 100
  @assignment_lock 200
  @review_lock 300

  @in_review_status 300

  @maint_status 999
  @maint_name "Under Maintenance"
  @ghost_name "Ghost"

  @diy_complete_lock 200

  @default_grade_scale %{"A" => "90", "B" => "80", "C" => "70", "D" => "60"}

  @doc """
  Gets a `Skoller.Schools.Class` by id.

  ## Examples

      iex> Skoller.Classes.get_class_by_id(1)
      {:ok, %Skoller.Schools.Class{}

  """
  def get_class_by_id(id) do
    Repo.get(Class, id)
  end

  @doc """
  Gets a `Skoller.Schools.Class` by id

  ## Examples

      iex> Skoller.Classes.get_class_by_id!(1)
      %Skoller.Schools.Class{}

  """
  def get_class_by_id!(id) do
    Repo.get!(Class, id)
  end

  def get_editable_class_by_id(id) do
    Repo.get_by(Class, id: id, is_editable: true)
  end

  @doc """
  Creates a `Skoller.Schools.Class` with changeset depending on `Skoller.Schools.School` tied to the `Skoller.Schools.ClassPeriod`

  ## Behavior:
   If there is no grade scale provided, a default is used: 

  ## Examples

      iex> Skoller.Classes.create_class(%{} = params)
      %Skoller.Schools.Class{}

  """
  def create_class(params, user \\ nil) do
    class_period_id = params |> Map.get(:class_period_id, Map.get(params, "class_period_id"))
    params = params |> put_grade_scale()

    changeset = class_period_id
    |> Schools.get_school_from_period()
    |> get_create_changeset(params)
    |> add_student_created_class_fields(user)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:class, changeset)
    |> Ecto.Multi.run(:class_status, &check_status(&1.class, %{params: params}))
    |> Repo.transaction()
  end

  @doc """
  Updates a `Skoller.Schools.Class` with changeset depending on `Skoller.Schools.School` tied to the `Skoller.Schools.ClassPeriod`

  ## Examples

      iex> Skoller.Classes.update_class(old_class, %{} = params)
      %Skoller.Schools.Class{}

  """
  def update_class(class_old, params) do
    changeset = class_old.class_period_id
    |> Schools.get_school_from_period()
    |> get_update_changeset(params, class_old)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:class, changeset)
    |> Ecto.Multi.run(:class_status, &check_status(&1.class, nil))
    |> Repo.transaction()
  end

  def get_editable_classes_subquery() do
    from(class in Class)
    |> where([class], class.is_editable == true)
  end

  @doc """
  Returns a count of `Skoller.Schools.Class` using the id of `Skoller.Schools.ClassPeriod`

  ## Examples

      iex> val = Skoller.Classes.get_class_count_by_period(1)
      ...> Kernel.is_integer(val)
      true

  """
  def get_class_count_by_period(period_id) do
    from(c in Class)
    |> where([c], c.class_period_id == ^period_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the `Skoller.Class.Status` name and a count of `Skoller.Schools.Class` in the status

  ## Examples

      iex> Skoller.Classes.get_status_counts(1)
      [{status: name, count: num}]

  """
  def get_status_counts(school_id) do
    from(class in Class)
    |> join(:inner, [class], prd in ClassPeriod, class.class_period_id == prd.id)
    |> join(:full, [class, prd], status in Status, class.class_status_id == status.id)
    |> where([class, prd], prd.school_id == ^school_id)
    |> group_by([class, prd, status], [status.name])
    |> select([class, prd, status], %{status: status.name, count: count(class.id)})
    |> Repo.all()
  end

  @doc """
  Gets all `Skoller.Schools.Class` in a period that share a hash (hashed from syllabus url)

  ## Examples

      iex> Skoller.Classes.get_class_from_hash("123dadqwdvsdfscxsz", 1)
      [%Skoller.Schools.Class{}]

  """
  def get_class_from_hash(class_hash, period_id) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> where([class, period], period.id == ^period_id)
    |> where([class], class.class_upload_key == ^class_hash)
    |> Repo.all()
  end

  @doc """
  Gets class_id and school_id

  """
  def get_school_from_class_subquery(_params \\ %{})
  def get_school_from_class_subquery(%{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([c, p], p.school_id == ^school_id)
    |> select([c, p], %{class_id: c.id, school_id: p.school_id})
  end
  def get_school_from_class_subquery(_params) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> select([c, p], %{class_id: c.id, school_id: p.school_id})
  end

  def get_class_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  def get_completed_class_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.class_status_id == @completed_status)
    |> Repo.aggregate(:count, :id)
  end

  def get_class_in_review_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.class_status_id != @completed_status and c.class_status_id >= @in_review_status)
    |> Repo.aggregate(:count, :id)
  end

  def student_created_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.is_student_created == true)
    |> Repo.aggregate(:count, :id)
  end

  def classes_with_syllabus_subquery() do
    from(d in Doc)
    |> where([d], d.is_syllabus == true)
    |> distinct([d], d.class_id)
    |> order_by([d], asc: d.inserted_at)
  end

  def classes_completed_by_diy_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> join(:inner, [c, cs], l in Lock, l.class_id == c.id and l.class_lock_section_id == @diy_complete_lock and l.is_completed == true)
    |> join(:inner, [c, cs, l], u in User, u.id == l.user_id)
    |> join(:inner, [c, cs, l, u], r in UserRole, r.user_id == u.id)
    |> where([c, cs, l, u, r], r.role_id == @student_role)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  def evaluate_class_completion(%Class{class_status_id: @completed_status}, %Class{class_status_id: @completed_status}), do: nil
  def evaluate_class_completion(%Class{class_status_id: _old_status}, %Class{class_status_id: @completed_status} = class) do
    Task.start(NotificationHelper, :send_class_complete_notification, [class])
  end
  def evaluate_class_completion(_old_class, _class), do: nil

  def get_class_status_counts() do
    statuses = from(status in Status)
    |> join(:left, [status], class in Class, status.id == class.class_status_id)
    |> join(:left, [status, class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [status, class, period], sch in School, sch.id == period.school_id and sch.is_auto_syllabus == true)
    |> where([status], status.id not in [@needs_syllabus_status, @completed_status])
    |> group_by([status, class, period, sch], [status.id, status.name, status.is_complete])
    |> select([status, class, period, sch], %{id: status.id, name: status.name, classes: count(class.id)})
    |> Repo.all()

    maint = from(class in Class)
    |> where([class], class.is_editable == false)
    |> select([class], %{id: @maint_status, name: @maint_name, classes: count(class.id)})
    |> Repo.all()

    statuses ++ maint
  end

  def get_classes_by_school(school_id, filters \\ nil) do
    #TODO: Filter ClassPeriod
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [class], prof in Professor, class.professor_id == prof.id)
    |> where([class, period], period.school_id == ^school_id)
    |> where([class, period, prof], ^filter(filters))
    |> select([class, period, prof], %{class: class, professor: prof, class_period: period})
    |> Repo.all()
  end

  def get_class_status(%Class{} = class) do
    class = class |> Repo.preload(:class_status)
    get_status(class)
  end
  def get_class_status(%Status{} = class_status) do
    get_status(%{class_status: class_status})
  end

  def need_syllabus_status_class_subquery() do
    from(c in Class)
    |> where([c], c.class_status_id == @needs_syllabus_status)
  end

  # A new class has been added, and it is a class that will never have a syllabus.
  def check_status(%Class{class_status_id: nil, is_syllabus: false} = class, _params) do
    class |> set_status(@completed_status)
  end
  def check_status(%Class{class_status_id: status, is_syllabus: false} = class, _params) when status < @completed_status do
    class |> set_status(@completed_status)
  end
  # A new class has been added.
  def check_status(%Class{class_status_id: nil} = class, _params) do
    class |> set_status(@needs_syllabus_status)
  end
  # A syllabus has been added to a class that needs a syllabus.
  def check_status(%Class{class_status_id: @needs_syllabus_status} = class, %{doc: %{is_syllabus: true} = doc}) do
    case doc.class_id == class.id do
      true -> class |> set_status(@weight_status)
      false -> {:error, %{class_id: "Class and doc do not match"}}
    end
  end
  # A class in the change status has a change request completed.
  def check_status(%Class{class_status_id: @change_status} = class, %{change_request: %{is_completed: true} = change_request}) do
    case change_request.class_id == class.id do
      true -> check_req_status(class)
      false -> {:error, %{class_id: "Class and change request do not match"}}
    end
  end
  # A class in the change status has a student request completed.
  def check_status(%Class{class_status_id: @change_status} = class, %{student_request: %{is_completed: true} = student_request}) do
    case student_request.class_id == class.id do
      true -> check_req_status(class)
      false -> {:error, %{class_id: "Class and student request do not match"}}
    end
  end
  # A class has a change request created.
  def check_status(%Class{} = class, %{change_request: %{is_completed: false} = change_request}) do
    case change_request.class_id == class.id do
      true -> class |> Repo.preload(:class_status) |> change_status_check()
      false -> {:error, %{class_id: "Class and change request do not match"}}
    end
  end
  # A class has a help request created.
  def check_status(%Class{} = class, %{help_request: %{is_completed: false} = help_request}) do
    case help_request.class_id == class.id do
      true -> class |> Repo.preload(:class_status) |> help_status_check()
      false -> {:error, %{class_id: "Class and change request do not match"}}
    end
  end
  # A class has been fully unlocked. Get the highest lock
  def check_status(%Class{} = class, %{unlock: unlock}) when is_list(unlock) do
    max_lock = unlock
    |> Enum.filter(& elem(&1, 1).is_completed and elem(&1, 1).class_id == class.id)
    |> Enum.reduce(0, &case elem(&1, 1).class_lock_section_id > &2 do
        true -> elem(&1, 1).class_lock_section_id
        false -> &2
      end)
    case max_lock do
      @review_lock -> class |> set_status(@completed_status)
      @assignment_lock -> class |> set_status(@completed_status)
      @weight_lock -> class |> set_status(@assignment_lock)
      _ -> {:ok, nil}
    end
  end
  # A class has been unlocked in the weights status.
  def check_status(%Class{class_status_id: @weight_status} = class, %{unlock: %{class_lock_section_id: @weight_lock, is_completed: true} = unlock}) do
    case unlock.class_id == class.id do
      true -> class |> set_status(@assignment_status)
      false -> {:error, %{class_id: "Class and lock do not match"}}
    end
  end
  # A class has been unlocked in the assignments status.
  def check_status(%Class{class_status_id: @assignment_status} = class, %{unlock: %{class_lock_section_id: @assignment_lock, is_completed: true} = unlock}) do
    case unlock.class_id == class.id do
      true -> class |> set_status(@review_status)
      false -> {:error, %{class_id: "Class and lock do not match"}}
    end
  end
  # A class has been unlocked from the review status.
  def check_status(%Class{class_status_id: @review_status} = class, %{unlock: %{class_lock_section_id: @review_lock, is_completed: true} = unlock}) do
    case unlock.class_id == class.id do
      true -> class |> set_status(@completed_status)
      false -> {:error, %{class_id: "Class and lock do not match"}}
    end
  end
  # A student enrolled into a ghost class.
  def check_status(%Class{is_ghost: true} = class, %{student_class: student_class}) do
    case student_class.class_id == class.id do
      true -> class |> remove_ghost()
      false -> {:error, %{class_id: "Class id enrolled into does not match"}}
    end
  end
  # A student created a student request.
  def check_status(%Class{} = class, %{student_request: %{is_completed: false} = student_request}) do
    case student_request.class_id == class.id do
      true -> class |> Repo.preload(:class_status) |> set_request_status()
      false -> {:error, %{class_id: "Class id enrolled into does not match"}}
    end
  end
  def check_status(_class, _params), do: {:ok, nil}

  defp set_status(class, status) do
    Ecto.Changeset.change(class, %{class_status_id: status})
    |> Repo.update()
  end

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
        class |> set_status(@completed_status)
      _results -> 
        {:ok, nil}
    end
  end

  defp remove_ghost(%{} = class) do
    class
    |> Ecto.Changeset.change(%{is_ghost: false})
    |> Repo.update()
  end

  defp change_status_check(%{class_status: %{is_complete: false}}) do
    {:error, %{error: "Class is incomplete, use Help Request."}}
  end
  defp change_status_check(%{class_status: %{is_complete: true}} = class) do
    class |> set_status(@change_status)
  end

  defp help_status_check(%{class_status: %{is_complete: true}}) do
    {:error, %{error: "Class is complete, use Change Request."}}
  end
  defp help_status_check(%{class_status: %{is_complete: false}} = class) do
    class |> set_status(@help_status)
  end

  defp set_request_status(%{class_status: %{is_complete: true}} = class) do
    class |> set_status(@change_status)
  end
  defp set_request_status(%{class_status: %{is_complete: false}} = class) do
    class |> set_status(@help_status)
  end

  defp get_status(%{class_status: %{is_complete: false}, is_ghost: true}), do: @ghost_name
  defp get_status(%{class_status: status}), do: status.name

  defp filter(nil), do: true
  defp filter(%{} = params) do
    dynamic = params["or"] != "true"

    dynamic
    |> prof_filter(params)
    |> prof_id_filter(params)
    |> name_filter(params)
    |> number_filter(params)
  end

  defp prof_filter(dynamic, %{"professor_name" => filter, "or" => "true"}) do
    prof_filter = filter <> "%"
    dynamic([class, period, prof], ilike(prof.name_last, ^prof_filter) or ilike(prof.name_first, ^prof_filter) or ^dynamic)
  end
  defp prof_filter(dynamic, %{"professor_name" => filter}) do
    prof_filter = filter <> "%"
    dynamic([class, period, prof], (ilike(prof.name_last, ^prof_filter) or ilike(prof.name_first, ^prof_filter)) and ^dynamic)
  end
  defp prof_filter(dynamic, _), do: dynamic

  defp prof_id_filter(dynamic, %{"professor_id" => filter, "or" => "true"}) do
    dynamic([class, period, prof], prof.id == ^filter or ^dynamic)
  end
  defp prof_id_filter(dynamic, %{"professor_id" => filter}) do
    dynamic([class, period, prof], prof.id == ^filter and ^dynamic)
  end
  defp prof_id_filter(dynamic, _), do: dynamic

  defp name_filter(dynamic, %{"class_name" => filter, "or" => "true"}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) or ^dynamic)
  end
  defp name_filter(dynamic, %{"class_name" => filter}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) and ^dynamic)
  end
  defp name_filter(dynamic, _), do: dynamic

  defp number_filter(dynamic, %{"class_number" => filter, "or" => "true"}) do
    number_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.number, ^number_filter) or ^dynamic)
  end
  defp number_filter(dynamic, %{"class_number" => filter}) do
    number_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.number, ^number_filter) and ^dynamic)
  end
  defp number_filter(dynamic, _), do: dynamic

  defp get_create_changeset(%{is_university: true}, params) do
    Universities.get_changeset(params)
  end
  defp get_create_changeset(%{is_university: false}, params) do
    HighSchools.get_changeset(params)
  end
  defp get_update_changeset(%{is_university: true}, params, old_class) do
    Universities.get_changeset(old_class, params)
  end
  defp get_update_changeset(%{is_university: false}, params, old_class) do
    HighSchools.get_changeset(old_class, params)
  end

  defp add_student_created_class_fields(changeset, %{student: nil}), do: changeset
  defp add_student_created_class_fields(changeset, %{student: _}) do
    changeset |> Ecto.Changeset.change(%{is_student_created: true})
  end
  defp add_student_created_class_fields(changeset, _user), do: changeset

  defp put_grade_scale(%{"grade_scale" => _} = params), do: params
  defp put_grade_scale(%{} = params) do
    params |> Map.put("grade_scale", @default_grade_scale)
  end
end