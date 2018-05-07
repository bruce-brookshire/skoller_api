defmodule Skoller.Students do
  @moduledoc """
  The Students context.
  """
  
  alias Skoller.Repo
  alias Skoller.Class.StudentClass
  alias Skoller.Schools.Class
  alias Skoller.Schools.School
  alias Skoller.Students.Student
  alias Skoller.School.FieldOfStudy
  alias Skoller.School.StudentField
  alias Skoller.Classes
  alias Skoller.Classes.Status
  alias Skoller.Professors.Professor
  alias Skoller.Schools.ClassPeriod
  alias SkollerWeb.Helpers.ClassCalcs
  alias SkollerWeb.Helpers.ModHelper
  alias Skoller.Class.StudentAssignment
  alias SkollerWeb.Helpers.AssignmentHelper
  alias Skoller.Assignment.Mod
  alias Skoller.Assignment.Mod.Action
  alias Skoller.Assignments.Mods
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Class.Assignment
  alias Skoller.Class.Weight

  import Ecto.Query

  @community_threshold 2
  @link_length 5

  def get_active_student_class_by_ids(class_id, student_id) do
    from(sc in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> join(:inner, [sc], class in subquery(Classes.get_editable_classes_subquery()), class.id == sc.class_id)
    |> where([sc], sc.class_id == ^class_id)
    |> Repo.one()
  end

  def get_enrolled_class_by_ids(class_id, student_id) do
    Repo.get_by(StudentClass, student_id: student_id, class_id: class_id, is_dropped: false)
  end

  def get_enrolled_class_by_ids!(class_id, student_id) do
    Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id, is_dropped: false)
  end

  def get_student_class_by_id(id) do
    Repo.get(StudentClass, id)
  end

  def get_student_class_by_id!(id) do
    Repo.get!(StudentClass, id)
  end

  def enroll_in_class(class_id, params, opts \\ []) do
    changeset = StudentClass.changeset(%StudentClass{}, params)
    |> add_enrolled_by(opts)
    
    class = Classes.get_class_by_id(class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:student_class, changeset)
    |> Ecto.Multi.run(:enrollment_link, &generate_enrollment_link(&1.student_class))
    |> Ecto.Multi.run(:status, &Classes.check_status(class, &1))
    |> Ecto.Multi.run(:student_assignments, &AssignmentHelper.insert_student_assignments(&1))
    |> Ecto.Multi.run(:mods, &add_public_mods(&1))
    |> Ecto.Multi.run(:auto_approve, &auto_approve_mods(&1))
    
    case multi |> Repo.transaction() do
      {:ok, trans} -> 
        {:ok, get_student_class_by_id(trans.student_class.id)}
      error -> error
    end
  end

  def update_enrolled_class(old_student_class, params) do
    old_student_class
    |> StudentClass.update_changeset(params)
    |> Repo.update()
  end

  def drop_enrolled_class(student_class) do
    student_class
    |> Ecto.Changeset.change(%{"is_dropped" => true})
    |> Repo.update()
  end

  def get_enrollment_by_class_id(id) do
    from(sc in subquery(get_enrollment_by_class_id_subquery(id)))
    |> Repo.aggregate(:count, :id)
  end

  def get_enrollment_by_class_id_subquery(id) do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false and sc.class_id == ^id)
  end

  @doc """
  Returns `Skoller.Class.StudentClass` with `Skoller.Schools.Class` that a `Skoller.Students.Student` currently has.

  ## Examples

      iex> val = Skoller.Students.get_enrolled_classes_by_student_id(1)
      [%Skoller.Class.StudentClass{class: %Skoller.Schools.Class{}}]

  """
  def get_enrolled_classes_by_student_id(student_id) do
    #TODO: Filter ClassPeriod
    from(classes in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> Repo.all()
    |> Repo.preload(:class)
  end

  def get_enrolled_classes_by_student_id_subquery(student_id) do
    #TODO: Filter ClassPeriod
    from(sc in StudentClass)
    |> where([sc], sc.student_id == ^student_id and sc.is_dropped == false)
  end

  @doc """
  Returns the count of students in a given `Skoller.Schools.ClassPeriod`.

  ## Examples

      iex> val = Skoller.Students.get_enrollment_by_period_id(1)
      ...>Kernel.is_integer(val)
      true

  """
  def get_enrollment_by_period_id(period_id) do
    from(sc in subquery(get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], c in Class, c.id == sc.class_id)
    |> where([sc, c], c.class_period_id == ^period_id)
    |> distinct([sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the `Skoller.Schools.School` and a count of `Skoller.Students.Student`

  ## Examples

      iex> Skoller.Students.get_schools_with_enrollment()
      [{school: %Skoller.Schools.School, students: num}]

  """
  def get_schools_with_enrollment() do
    from(school in School)
    |> join(:left, [school], student in subquery(get_school_enrollment_subquery()), student.school_id == school.id)
    |> select([school, student], %{school: school, students: fragment("coalesce(?, 0)", student.count)})
    |> Repo.all()
  end

  @doc """
  Returns the `Skoller.School.FieldOfStudy` and a count of `Skoller.Students.Student`

  ## Examples

      iex> Skoller.Students.get_field_of_study_count_by_school_id()
      [{field: %Skoller.School.FieldOfStudy, count: num}]

  """
  def get_field_of_study_count_by_school_id(school_id) do
    (from fs in FieldOfStudy)
    |> join(:left, [fs], st in StudentField, fs.id == st.field_of_study_id)
    |> where([fs], fs.school_id == ^school_id)
    |> group_by([fs, st], [fs.field, fs.id])
    |> select([fs, st], %{field: fs, count: count(st.id)})
    |> Repo.all()
  end

  @doc """
  Returns a subquery that provides a unique list of `Skoller.Schools.School` ids and `Skoller.Students.Student` ids

  """
  def get_schools_for_student_subquery() do
    from(student in Student)
    |> join(:inner, [student], sc in subquery(get_enrolled_student_classes_subquery()), sc.student_id == student.id)
    |> join(:inner, [student, sc], class in subquery(Classes.get_school_from_class_subquery()), sc.class_id == class.class_id)
    |> distinct([student, sc, class], [student.id, class.school_id])
    |> select([student, sc, class], %{student_id: student.id, school_id: class.school_id})
  end

  def get_student_subquery(_params \\ %{})
  @doc """
  Returns a subquery that provides a list of `Skoller.Students.Student` by `Skoller.Schools.School`

  """
  def get_student_subquery(%{"school_id" => _school_id} = params) do
    from(s in Student)
    |> join(:inner, [s], sc in StudentClass, sc.student_id == s.id)
    |> join(:inner, [s, sc], c in subquery(Classes.get_school_from_class_subquery(params)), c.class_id == sc.class_id)
    |> where([s, sc], sc.is_dropped == false)
    |> distinct([s], s.id)
  end
  @doc """
  Returns a subquery that provides a list of `Skoller.Students.Student`

  """
  def get_student_subquery(_params) do
    from(s in Student)
  end

  @doc """
  Returns a subquery that provides a list of `Skoller.Class.StudentClass` where the classes are not dropped by `Skoller.Schools.School`

  """
  def get_enrolled_student_classes_subquery(params \\ %{}) do
    from(sc in StudentClass)
    |> join(:inner, [sc], c in subquery(Classes.get_school_from_class_subquery(params)), c.class_id == sc.class_id)
    |> where([sc], sc.is_dropped == false)
  end

  @doc """
  Returns a subquery that provides a list of `Skoller.Schools.Class`

  """
  def get_enrolled_classes_subquery() do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
    |> distinct([sc], sc.class_id)
  end

  def get_enrolled_class_with_syllabus_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(Classes.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> join(:inner, [c, cs], d in subquery(Classes.classes_with_syllabus_subquery()), d.class_id == c.id)
    |> where([c], fragment("exists(select 1 from student_classes sc where sc.class_id = ? and sc.is_dropped = false)", c.id))
    |> where([c, cs, d], fragment("?::date", d.inserted_at) >= ^dates.date_start and fragment("?::date", d.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  def un_read_assignment(student_id, assignment_id) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, sc.id == sa.student_class_id)
    |> where([sa], sa.assignment_id == ^assignment_id)
    |> where([sa, sc], sc.student_id != ^student_id)
    |> Repo.all()
    |> Enum.map(&Repo.update(Ecto.Changeset.change(&1, %{is_read: false})))
  end

  @doc """
   Shows all `Skoller.Schools.Class`. Can be used as a search with multiple filters.

  ## Filters:
  * school
    * `Skoller.Schools.School` :id
  * professor.name
    * `Skoller.Professors.Professor` :name
  * class.status
    * `Skoller.Classes.Status` :id
    * For ghost classes, use 0.
  * class.name
    * `Skoller.Schools.Class` :name
  * class.number
    * `Skoller.Schools.Class` :number
  * class.meet_days
    * `Skoller.Schools.Class` :meet_days
  * class.length
    * 1st Half
    * 2nd Half
    * Full Term
    * Custom

  """
  def get_classes_with_enrollment(params) do
    #TODO: Filter ClassPeriod
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [class], prof in Professor, class.professor_id == prof.id)
    |> join(:inner, [class, period, prof], school in School, school.id == period.school_id)
    |> join(:inner, [class, period, prof, school], status in Status, status.id == class.class_status_id)
    |> join(:left, [class, period, prof, school, status], enroll in subquery(count_subquery()), enroll.class_id == class.id)
    |> where([class, period, prof], ^filter(params))
    |> select([class, period, prof, school, status, enroll], %{class: class, class_period: period, professor: prof, school: school, class_status: status, enroll: enroll})
    |> Repo.all()
  end

  def get_student_assignments(student_id, filters) do
    from(sc in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> join(:inner, [sc], class in Class, class.id == sc.class_id)
    |> join(:inner, [sc, class], cs in Status, cs.id == class.class_status_id)
    |> where([sc, class, cs], cs.is_complete == true)
    |> where_filters(filters)
    |> Repo.all()
    |> Enum.flat_map(&ClassCalcs.get_assignments_with_relative_weight(&1))
    |> Enum.map(&Map.put(&1, :is_pending_mods, is_pending_mods(&1)))
    |> get_student_assingment_filter(filters)
  end

  def get_student_assignment_by_id(id, :weight) do
    from(sc in subquery(get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], sa in StudentAssignment, sc.id == sa.student_class_id)
    |> join(:inner, [sc, sa], class in Class, class.id == sc.class_id)
    |> join(:inner, [sc, sa, class], cs in Status, cs.id == class.class_status_id)
    |> where([sc, sa], sa.id == ^id)
    |> where([sc, sa, class, cs], cs.is_complete == true)
    |> Repo.all()
    |> Enum.flat_map(&ClassCalcs.get_assignments_with_relative_weight(&1))
    |> Enum.filter(& to_string(&1.id) == id)
    |> List.first()
  end
  def get_student_assignment_by_id(id) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, sc.id == sa.student_class_id)
    |> join(:inner, [sa, sc], class in Class, sc.class_id == class.id)
    |> where([sa], sa.id == ^id)
    |> where([sa, sc, class], class.is_editable == true)
    |> Repo.one()
  end

  def get_common_notification_times(num, params) do
    from(s in Student)
    |> join(:inner, [s], sc in subquery(get_enrolled_student_classes_subquery(params)), sc.student_id == s.id)
    |> join(:inner, [s, sc], sfc in subquery(Classes.get_school_from_class_subquery(params)), sfc.class_id == sc.class_id)
    |> join(:inner, [s, sc, sfc], sch in School, sch.id == sfc.school_id)
    |> group_by([s, sc, sfc, sch], [s.notification_time, sch.timezone])
    |> select([s, sc, sfc, sch], %{notification_time: s.notification_time, timezone: sch.timezone, count: count(s.notification_time)})
    |> order_by([s], desc: count(s.notification_time))
    |> limit([s], ^num)
    |> Repo.all()
  end

  def get_communities(threshold \\ @community_threshold) do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
    |> group_by([sc], sc.class_id)
    |> having([sc], count(sc.id) >= ^threshold)
    |> select([sc], %{class_id: sc.class_id, count: count(sc.id)})
  end

  def create_student_assignment(params) do
    changeset = Assignment.student_changeset(%Assignment{}, params)
    |> Ecto.Changeset.change(%{from_mod: true})
    |> validate_class_weight()

    Ecto.Multi.new
    |> Ecto.Multi.run(:assignment, &insert_or_get_assignment(&1, changeset))
    |> Ecto.Multi.run(:student_assignment, &insert_student_assignment(&1, params))
    |> Ecto.Multi.run(:mod, &ModHelper.insert_new_mod(&1, params))
    |> Repo.transaction()
  end

  def update_student_assignment(old, params) do
    changeset = old
    |> StudentAssignment.changeset_update(params)
    |> validate_class_weight()

    Ecto.Multi.new
    |> Ecto.Multi.update(:student_assignment, changeset)
    |> Ecto.Multi.run(:mod, &ModHelper.insert_update_mod(&1, changeset, params))
    |> Repo.transaction()
  end
  
  def get_student_class_by_enrollment_link(link) do
    student_class_id = link |> String.split_at(@link_length) |> elem(1)
    Repo.get_by!(StudentClass, enrollment_link: link, id: student_class_id)
    |> Repo.preload([:student, :class])
  end

  def enroll_by_link(link, student_id, params) do
    sc = get_student_class_by_enrollment_link(link)
    params = params |> Map.put("class_id", sc.class_id) |> Map.put("student_id", student_id)
    enroll_in_class(sc.class_id, params, [enrolled_by: sc.id])
  end

  defp add_enrolled_by(changeset, opts) do
    case opts |> List.keytake(:enrolled_by, 0) do
      nil -> changeset
      val -> 
        val = val 
        |> elem(0) 
        |> elem(1)

        changeset |> Ecto.Changeset.change(%{enrolled_by: val})
    end
  end

  def generate_enrollment_link(%StudentClass{id: id} = student_class) do
    link = @link_length
    |> :crypto.strong_rand_bytes() 
    |> Base.url_encode64 
    |> binary_part(0, @link_length)
    |> Kernel.<>(to_string(id))

    student_class
    |> Ecto.Changeset.change(%{enrollment_link: link})
    |> Repo.update()
  end

  # 1. Check for existing base Assignment, pass to next multi call.
  # 2. Check for existing Student Assignment, pass to next multi call. This means that a student has this assignment from a combination of mods.
  # 3. Create assignment, pass to next multi call.
  defp insert_or_get_assignment(_, %Ecto.Changeset{valid?: false} = changeset), do: {:error, changeset}
  defp insert_or_get_assignment(_, changeset) do
    assign = from(assign in Assignment)
    |> where([assign], assign.class_id == ^Ecto.Changeset.get_field(changeset, :class_id))
    |> where([assign], assign.name == ^Ecto.Changeset.get_field(changeset, :name))
    |> compare_weights(changeset)
    |> compare_dates(changeset)
    |> Repo.all()

    case assign do
      [] -> changeset |> check_student_assignment()
      assign -> {:ok, assign |> List.first}
    end
  end

  # Checks to see if an incoming changeset is identical to another student's assignment in the same class.
  defp check_student_assignment(changeset) do
    assign = from(assign in StudentAssignment)
    |> join(:inner, [assign], sc in StudentClass, sc.id == assign.student_class_id)
    |> where([assign, sc], sc.class_id == ^Ecto.Changeset.get_field(changeset, :class_id))
    |> where([assign], assign.name == ^Ecto.Changeset.get_field(changeset, :name))
    |> compare_weights(changeset)
    |> compare_dates(changeset)
    |> Repo.all()

    case assign do
      [] -> changeset |> Repo.insert()
      assign -> {:ok, assign |> List.first}
    end
  end

  # 1. Check to see if assignment exists in StudentAssignment for student, if not, insert, else error.
  defp insert_student_assignment(%{assignment: %Assignment{} = assignment}, params) do
    params = params |> Map.put("assignment_id", assignment.id)
    changeset = StudentAssignment.changeset(%StudentAssignment{}, params)

    student_assign = from(assign in StudentAssignment)
    |> where([assign], assign.student_class_id == ^params["student_class_id"])
    |> where([assign], assign.assignment_id == ^assignment.id)
    |> Repo.all()

    case student_assign do
      [] -> Repo.insert(changeset)
      _ -> {:error, %{student_assignment: "Assignment is already added."}}
    end
  end
  defp insert_student_assignment(%{assignment: %StudentAssignment{} = student_assignment}, params) do
    params = params |> Map.put("assignment_id", student_assignment.assignment_id)
    changeset = StudentAssignment.changeset(%StudentAssignment{}, params)

    student_assign = from(assign in StudentAssignment)
    |> where([assign], assign.student_class_id == ^params["student_class_id"])
    |> where([assign], assign.assignment_id == ^student_assignment.assignment_id)
    |> Repo.all()

    case student_assign do
      [] -> Repo.insert(changeset)
      _ -> {:error, %{student_assignment: "Assignment is already added."}}
    end
  end

  defp compare_dates(query, changeset) do
    case Ecto.Changeset.get_field(changeset, :due) do
      nil -> 
        query |> where([assign], is_nil(assign.due))
      due -> 
        query |> where([assign], ^due == assign.due)
    end
  end

  defp compare_weights(query, changeset) do
    case Ecto.Changeset.get_field(changeset, :weight_id) do
      nil ->
        query |> where([assign], is_nil(assign.weight_id))
      weight_id -> 
        query |> where([assign], ^weight_id == assign.weight_id)
    end
  end

  defp validate_class_weight(%Ecto.Changeset{changes: %{weight_id: nil}} = changeset), do: changeset
  defp validate_class_weight(%Ecto.Changeset{changes: %{weight_id: weight_id}, valid?: true} = changeset) do
    class_id = changeset |> get_class_id_from_student_assignment_changeset()
    case Repo.get_by(Weight, class_id: class_id, id: weight_id) do
      nil -> changeset |> Ecto.Changeset.add_error(:weight_id, "Weight class combination invalid")
      _ -> changeset
    end
  end
  defp validate_class_weight(changeset), do: changeset

  defp get_class_id_from_student_assignment_changeset(changeset) do
    case changeset |> Ecto.Changeset.get_field(:student_class_id) do
      nil -> changeset |> Ecto.Changeset.get_field(:class_id)
      val -> get_student_class_by_id!(val) |> Map.get(:class_id)
    end
  end

  defp auto_approve_mods(%{mods: mods}) do
    status = mods
    |> Enum.map(&ModHelper.process_auto_update(&1))

    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp auto_approve_mods(_params), do: {:ok, nil}

  defp add_public_mods(%{student_class: student_class}) do
    mods = from(mod in Mod)
    |> join(:inner, [mod], class in subquery(Mods.get_class_from_mod_subquery()), mod.id == class.mod_id)
    |> where([mod], mod.is_private == false)
    |> where([mod, class], class.class_id == ^student_class.class_id)
    |> Repo.all()
    
    status = mods |> Enum.map(&insert_mod_action(student_class, &1))
    
    status |> Enum.find({:ok, mods}, &RepoHelper.errors(&1))
  end

  defp insert_mod_action(student_class, %Mod{} = mod) do
    Repo.insert(%Action{is_accepted: nil, student_class_id: student_class.id, assignment_modification_id: mod.id})
  end

  defp get_student_assingment_filter(enumerable, params) do
    enumerable
    |> date_filter(params)
    |> completed_filter(params)
  end

  defp is_pending_mods(assignment) do
    case ModHelper.pending_mods_for_assignment(assignment) do
      [] -> false
      _ -> true
    end
  end

  defp date_filter(enumerable, %{"date" => date}) do
    {:ok, date, _offset} = date |> DateTime.from_iso8601()
    enumerable
    |> Enum.filter(&not(is_nil(&1.due)) and DateTime.compare(&1.due, date) in [:gt, :eq] and &1.is_completed == false)
    |> order()
  end
  defp date_filter(enumerable, _params), do: enumerable

  defp completed_filter(enumerable, %{"is_complete" => is_complete}) do
    enumerable
    |> Enum.filter(& to_string(&1.is_completed) == is_complete)
  end
  defp completed_filter(enumerable, _params), do: enumerable

  defp where_filters(query, params) do
    query
    |> class_filter(params)
  end

  defp class_filter(query, %{"class" => id}) do
    query
    |> where([sc], sc.class_id == ^id)
  end
  defp class_filter(query, _params), do: query

  defp filter(%{} = params) do
    dynamic = params["or"] != "true"

    dynamic
    |> school_filter(params)
    |> prof_filter(params)
    |> prof_id_filter(params)
    |> status_filter(params)
    |> ghost_filter(params)
    |> maint_filter(params)
    |> name_filter(params)
    |> number_filter(params)
    |> day_filter(params)
  end

  defp school_filter(dynamic, %{"school" => filter, "or" => "true"}) do
    dynamic([class, period, prof], period.school_id == ^filter or ^dynamic)
  end
  defp school_filter(dynamic, %{"school" => filter}) do
    dynamic([class, period, prof], period.school_id == ^filter and ^dynamic)
  end
  defp school_filter(dynamic, _), do: dynamic

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

  defp status_filter(dynamic, %{"class_status" => "0", "or" => "true"}) do
    dynamic([class, period, prof], class.is_ghost == true or ^dynamic)
  end
  defp status_filter(dynamic, %{"class_status" => filter, "or" => "true"}) do
    dynamic([class, period, prof], class.class_status_id == ^filter or ^dynamic)
  end
  defp status_filter(dynamic, %{"class_status" => "0"}) do
    dynamic([class, period, prof], class.is_ghost == true and ^dynamic)
  end
  defp status_filter(dynamic, %{"class_status" => filter}) do
    dynamic([class, period, prof], class.class_status_id == ^filter and ^dynamic)
  end
  defp status_filter(dynamic, _), do: dynamic

  defp ghost_filter(dynamic, %{"class_status" => "0"}), do: dynamic
  defp ghost_filter(dynamic, %{"ghost" => "true"}) do
    dynamic([class, period, prof], class.is_ghost == true and ^dynamic)
  end
  defp ghost_filter(dynamic, %{"ghost" => "false"}) do
    dynamic([class, period, prof], class.is_ghost == false and ^dynamic)
  end
  defp ghost_filter(dynamic, _), do: dynamic

  defp maint_filter(dynamic, %{"class_maint" => "true"}) do
    dynamic([class, period, prof], class.is_editable == false and ^dynamic)
  end
  defp maint_filter(dynamic, %{"class_maint" => "false"}) do
    dynamic([class, period, prof], class.is_editable == true and ^dynamic)
  end
  defp maint_filter(dynamic, _), do: dynamic

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

  defp day_filter(dynamic, %{"class_meet_days" => filter, "or" => "true"}) do
    dynamic([class, period, prof], class.meet_days == ^filter or ^dynamic)
  end
  defp day_filter(dynamic, %{"class_meet_days" => filter}) do
    dynamic([class, period, prof], class.meet_days == ^filter and ^dynamic)
  end
  defp day_filter(dynamic, _), do: dynamic

  defp get_school_enrollment_subquery() do
    from(s in subquery(get_schools_for_student_subquery()))
    |> group_by([s], s.school_id)
    |> select([s], %{school_id: s.school_id, count: count(s.student_id)})
  end

  defp count_subquery() do
    from(c in Class)
    |> join(:left, [c], sc in StudentClass, c.id == sc.class_id)
    |> where([c, sc], sc.is_dropped == false)
    |> group_by([c, sc], c.id)
    |> select([c, sc], %{class_id: c.id, count: count(sc.id)})
  end

  defp order(enumerable) do
    enumerable
    |> Enum.sort(&DateTime.compare(&1.due, &2.due) in [:lt, :eq])
  end
end
