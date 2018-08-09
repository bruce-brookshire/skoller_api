defmodule Skoller.Students do
  @moduledoc """
  The Students context.
  """
  
  alias Skoller.Repo
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Classes.Class
  alias Skoller.Schools.School
  alias Skoller.Students.Student
  alias Skoller.Classes
  alias Skoller.Classes.Status
  alias Skoller.Professors.Professor
  alias Skoller.Periods.ClassPeriod
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Mods.Mod
  alias Skoller.Mods.Action
  alias Skoller.Mods
  alias Skoller.Students.FieldOfStudy, as: StudentField
  alias Skoller.FieldsOfStudy.FieldOfStudy
  alias Skoller.StudentAssignments
  alias Skoller.StudentClasses
  alias Skoller.AutoUpdates
  alias Skoller.MapErrors

  import Ecto.Query

  require Logger

  @community_threshold 2
  @link_length 5
  @enrollment_limit 15

  @doc """
  Gets a student by id.

  ## Returns
  `Skoller.Students.Student` or `Ecto.NoResultsError`
  """
  def get_student_by_id!(student_id) do
    Repo.get!(Student, student_id)
  end

  @doc """
  Gets students in a class. Includes previously-enrolled students.

  ## Returns
  `[Skoller.StudentClasses.StudentClass]` or `[]`
  """
  def get_students_by_class(class_id) do
    from(sc in StudentClass)
    |> where([sc], sc.class_id == ^class_id)
    |> Repo.all()
  end

  @doc """
  Gets a student class where the class is editable and the student enrolled.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `nil`
  """
  def get_active_student_class_by_ids(class_id, student_id) do
    from(sc in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> join(:inner, [sc], class in subquery(Classes.get_editable_classes_subquery()), class.id == sc.class_id)
    |> where([sc], sc.class_id == ^class_id)
    |> Repo.one()
  end

  @doc """
  Gets a student class where the student enrolled.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `nil`
  """
  def get_enrolled_class_by_ids(class_id, student_id) do
    Repo.get_by(StudentClass, student_id: student_id, class_id: class_id, is_dropped: false)
  end

  @doc """
  Gets a student class where the student enrolled.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `Ecto.NoResultsError`
  """
  def get_enrolled_class_by_ids!(class_id, student_id) do
    Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id, is_dropped: false)
  end

  @doc """
  Enrolls a student in a class.

  ## Params
   * %{"color" => color}, sets the student class color.

  ## Returns
  `{:ok, Skoller.StudentClasses.StudentClass}` or `{:error, Ecto.Changeset}`
  """
  def enroll_in_class(student_id, class_id, params) do
    case Repo.get_by(StudentClass, student_id: student_id, class_id: class_id) do
      nil ->
        enroll(student_id, class_id, params)
      %{is_dropped: true} = sc ->
        enroll_in_dropped_class(sc)
      _sc ->
        {:error, nil, %{student_class: "class taken"}, nil}
    end
  end

  @doc """
  Updates an enrolled student in a class.

  ## Params
   * %{"color" => String}, sets the student class color.
   * %{"is_notifications" => Boolean}, sets the notifications for this class for this student.

  ## Returns
  `{:ok, Skoller.StudentClasses.StudentClass}` or `{:error, Ecto.Changeset}`
  """
  def update_enrolled_class(old_student_class, params) do
    old_student_class
    |> StudentClass.update_changeset(params)
    |> Repo.update()
  end

  @doc """
  Drops an enrolled student from a class.

  ## Returns
  `{:ok, Skoller.StudentClasses.StudentClass}` or `{:error, Ecto.Changeset}`
  """
  def drop_enrolled_class(student_class) do
    student_class
    |> Ecto.Changeset.change(%{is_dropped: true})
    |> Repo.update()
  end

  @doc """
  Gets a count of enrolled students per class

  ## Returns
  `Integer`
  """
  def get_enrollment_by_class_id(id) do
    from(sc in subquery(get_enrollment_by_class_id_subquery(id)))
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Subquery that gets enrolled students in a class by class id.
  """
  def get_enrollment_by_class_id_subquery(class_id) do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false and sc.class_id == ^class_id)
  end

  @doc """
  Subquery that gets enrolled students in a class
  """
  def enrolled_student_class_subquery() do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
  end

  @doc """
  Returns `Skoller.StudentClasses.StudentClass` with `Skoller.Classes.Class` that a `Skoller.Students.Student` currently has.

  ## Examples

      iex> val = Skoller.Students.get_enrolled_classes_by_student_id(1)
      [%Skoller.StudentClasses.StudentClass{class: %Skoller.Classes.Class{}}]

  """
  def get_enrolled_classes_by_student_id(student_id) do
    #TODO: Filter ClassPeriod
    from(classes in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> Repo.all()
    |> Repo.preload(:class)
  end

  @doc """
  Subquery for getting enrolled student classes by student.
  """
  def get_enrolled_classes_by_student_id_subquery(student_id) do
    #TODO: Filter ClassPeriod
    from(sc in StudentClass)
    |> where([sc], sc.student_id == ^student_id and sc.is_dropped == false)
  end

  @doc """
  Returns the count of students in a given `Skoller.Periods.ClassPeriod`.

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
  Returns a subquery that provides a list of enrolled students

  ## Params
   * `%{"school_id" => school_id}`, filters on school.
  """
  def get_student_subquery(_params \\ %{})
  def get_student_subquery(%{"school_id" => _school_id} = params) do
    from(s in Student)
    |> join(:inner, [s], sc in StudentClass, sc.student_id == s.id)
    |> join(:inner, [s, sc], c in subquery(Classes.get_school_from_class_subquery(params)), c.class_id == sc.class_id)
    |> where([s, sc], sc.is_dropped == false)
    |> distinct([s], s.id)
  end
  def get_student_subquery(_params) do
    from(s in Student)
  end

  @doc """
  Returns a subquery that provides a list of `Skoller.StudentClasses.StudentClass` where the classes are not dropped by `Skoller.Schools.School`

  """
  def get_enrolled_student_classes_subquery(params \\ %{}) do
    from(sc in StudentClass)
    |> join(:inner, [sc], c in subquery(Classes.get_school_from_class_subquery(params)), c.class_id == sc.class_id)
    |> where([sc], sc.is_dropped == false)
  end

  @doc """
  Returns a subquery that provides a list of `Skoller.Classes.Class`

  """
  def get_enrolled_classes_subquery() do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
    |> distinct([sc], sc.class_id)
  end

  @doc """
  Get a count of classes with syllabi and at least one student between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
  * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `Integer`
  """
  def get_enrolled_class_with_syllabus_count(%{date_start: date_start, date_end: date_end}, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(Classes.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> join(:inner, [c, cs], d in subquery(Classes.classes_with_syllabus_subquery()), d.class_id == c.id)
    |> where([c], fragment("exists(select 1 from student_classes sc where sc.class_id = ? and sc.is_dropped = false)", c.id))
    |> where([c, cs, d], fragment("?::date", d.inserted_at) >= ^date_start and fragment("?::date", d.inserted_at) <= ^date_end)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Un-reads an assignment for a student.

  ## Returns
  `[{:ok, Skoller.StudentAssignments.StudentAssignment}]`
  """
  def un_read_assignment(student_id, assignment_id) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, sc.id == sa.student_class_id)
    |> where([sa], sa.assignment_id == ^assignment_id)
    |> where([sa, sc], sc.student_id != ^student_id)
    |> Repo.all()
    |> Enum.map(&Repo.update(Ecto.Changeset.change(&1, %{is_read: false})))
  end

  @doc """
   Shows all `Skoller.Classes.Class` with enrollment. Can be used as a search with multiple filters.

  ## Filters:
  * school
    * `Skoller.Schools.School` :id
  * professor_name
    * `Skoller.Professors.Professor` :name
  * class_status
    * `Skoller.Classes.Status` :id
    * For ghost classes, use 0.
  * class_name
    * `Skoller.Classes.Class` :name
  * class_meet_days
    * `Skoller.Classes.Class` :meet_days

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

  @doc """
  Gets student assignments with relative weights for all completed, enrolled classes of `student_id`

  ## Filters
   * %{"class", class}, filter by class.
   * %{"date", Date}, filter by due date.
   * %{"is_complete", Boolean}, filter by completion.

  ## Returns
  `[%{Skoller.StudentClasses.StudentClass}]` with assignments and is_pending_mods or `[]`
  """
  def get_student_assignments(student_id, filters) do
    from(sc in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> join(:inner, [sc], class in Class, class.id == sc.class_id)
    |> join(:inner, [sc, class], cs in Status, cs.id == class.class_status_id)
    |> where([sc, class, cs], cs.is_complete == true)
    |> where_filters(filters)
    |> Repo.all()
    |> Enum.flat_map(&StudentAssignments.get_assignments_with_relative_weight(&1))
    |> Enum.map(&Map.put(&1, :is_pending_mods, is_pending_mods(&1)))
    |> get_student_assingment_filter(filters)
  end

  @doc """
  Gets a student assignment with relative weight by assignment id.

  ## Returns
  `[%{Skoller.StudentClasses.StudentClass}]` with assignments or `[]`
  """
  #TODO: make this and the one argument one, one function.
  def get_student_assignment_by_id(id, :weight) do
    from(sc in subquery(get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], sa in StudentAssignment, sc.id == sa.student_class_id)
    |> join(:inner, [sc, sa], class in Class, class.id == sc.class_id)
    |> join(:inner, [sc, sa, class], cs in Status, cs.id == class.class_status_id)
    |> where([sc, sa], sa.id == ^id)
    |> where([sc, sa, class, cs], cs.is_complete == true)
    |> Repo.all()
    |> Enum.flat_map(&StudentAssignments.get_assignments_with_relative_weight(&1))
    |> Enum.filter(& to_string(&1.id) == id)
    |> List.first()
  end

  @doc """
  Gets a student assignment by id in an editable class.

  ## Returns
  `Skoller.StudentAssignments.StudentAssignment` or `nil`
  """
  def get_student_assignment_by_id(id) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, sc.id == sa.student_class_id)
    |> join(:inner, [sa, sc], class in Class, sc.class_id == class.id)
    |> where([sa], sa.id == ^id)
    |> where([sa, sc, class], class.is_editable == true)
    |> Repo.one()
  end

  @doc """
  Gets the `num` most common notification times and timezone combos.

  ## Params
   * %{"school_id" => school_id}, filters by school.

  ## Returns
  `%{notification_time: Time, timezone: String, count: Integer}` or `[]`
  """
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

  @doc """
  Gets communities with a count of students.

  Communities are students with at least `threshold` enrolled students

  ## Returns
  `%{class_id: Id, count: Integer}`
  """
  def get_communities(threshold \\ @community_threshold) do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
    |> group_by([sc], sc.class_id)
    |> having([sc], count(sc.id) >= ^threshold)
    |> select([sc], %{class_id: sc.class_id, count: count(sc.id)})
  end
  
  @doc """
  Gets a student class from an enrollment link.

  ## Returns
  `Skoller.StudentClasses.StudentClass` with `:student` and `:class` loaded, or `Ecto.NoResultsError`
  """
  def get_student_class_by_enrollment_link(link) do
    student_class_id = link |> String.split_at(@link_length) |> elem(1)
    Repo.get_by!(StudentClass, enrollment_link: link, id: student_class_id)
    |> Repo.preload([:student, :class])
  end

  @doc """
  Enroll in a class with a student link.

  Similar to enroll_in_class/3
  """
  def enroll_by_link(link, student_id, params) do
    sc = get_student_class_by_enrollment_link(link)
    params = params |> Map.put("class_id", sc.class_id) |> Map.put("student_id", student_id)
    enroll(student_id, sc.class_id, params, [enrolled_by: sc.id])
  end

  @doc """
  Adds a field of study to a student.

  ## Returns
  `{:ok, Skoller.Students.FieldOfStudy}` with `:student` loaded or `{:error, Ecto.Changeset}`
  """
  def add_field_of_study(params) do
    changeset = StudentField.changeset(%StudentField{}, params)
    case changeset |> Repo.insert() do
      {:ok, results} -> results |> Repo.preload(:student)
      error -> error
    end
  end

  @doc """
  Gets a student field of study by student id and field id.

  ## Returns
  `{:ok, Skoller.Students.FieldOfStudy}` or `Ecto.NoResultsError`
  """
  def get_field_of_study_by_id!(student_id, field_of_study_id) do
    Repo.get_by!(StudentField, student_id: student_id, field_of_study_id: field_of_study_id)
  end

  @doc """
  Deletes a student field of study.

  ## Returns
  `{:ok, Skoller.Students.FieldOfStudy}` or `{:error, Ecto.Changeset}`
  """
  def delete_field_of_study(field) do
    Repo.delete(field)
  end

  @doc """
  Deletes all student fields of study by student.
  """
  def delete_fields_of_study_by_student_id(student_id) do
    from(sf in StudentField)
    |> where([sf], sf.student_id == ^student_id)
    |> Repo.delete_all()
  end

  @doc """
  Generates an enrollment link for a student that does not have one yet.

  ## Returns
  `{:ok, Skoller.Students.Student}` or `{:error, Ecto.Changeset}` or `{:ok, nil}` if there is already a link.
  """
  def generate_student_link(%Student{id: id, enrollment_link: nil} = student) do
    link = generate_link(id)
    
    student
    |> Ecto.Changeset.change(%{enrollment_link: link})
    |> Repo.update()
  end
  def generate_student_link(_student), do: {:ok, nil}

  @doc """
  Generates an enrollment link for a student class that does not have one yet.

  ## Returns
  `{:ok, Skoller.StudentClasses.StudentClass}` or `{:error, Ecto.Changeset}`
  """
  def generate_enrollment_link(%StudentClass{id: id} = student_class) do
    link = generate_link(id)

    Logger.info("Generating enrollment link " <> to_string(link) <> " for student class: " <> to_string(id))

    student_class
    |> Ecto.Changeset.change(%{enrollment_link: link})
    |> Repo.update()
  end

  @doc """
  Returns the `Skoller.FieldsOfStudy.FieldOfStudy` and a count of `Skoller.Students.Student`

  ## Examples

      iex> Skoller.Students.get_field_of_study_count_by_school_id()
      [{field: %Skoller.FieldsOfStudy.FieldOfStudy, count: num}]

  """
  def get_field_of_study_count() do
    (from fs in FieldOfStudy)
    |> join(:left, [fs], st in StudentField, fs.id == st.field_of_study_id)
    |> group_by([fs, st], [fs.field, fs.id])
    |> select([fs, st], %{field: fs, count: count(st.id)})
    |> Repo.all()
  end

  # Adds enrolled_by id to a student enrolling by a link.
  defp add_enrolled_by(%Ecto.Changeset{valid?: true} = changeset, opts) do
    case opts |> List.keytake(:enrolled_by, 0) do
      nil -> changeset
      val -> 
        val = val 
        |> elem(0) 
        |> elem(1)

        changeset |> Ecto.Changeset.change(%{enrolled_by: val})
    end
  end
  defp add_enrolled_by(changeset, _opts), do: changeset

  # Generates a link with @link_length random characters, with the id appended.
  defp generate_link(id) do
    @link_length
    |> :crypto.strong_rand_bytes() 
    |> Base.url_encode64 
    |> binary_part(0, @link_length)
    |> Kernel.<>(to_string(id))
  end

  defp auto_approve_mods(%{mods: mods}) do
    Logger.info("Processing mod auto updates")
    status = mods
    |> Enum.map(&AutoUpdates.process_auto_update(&1))

    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
  defp auto_approve_mods(_params), do: {:ok, nil}

  # Adds all non added public mods to a student enrolling in a class or re-enrolling..
  defp add_public_mods(%{student_class: student_class}) do
    Logger.info("Adding public mods for student class: " <> to_string(student_class.id))
    mods = from(mod in Mod)
    |> join(:inner, [mod], class in subquery(Mods.get_class_from_mod_subquery()), mod.id == class.mod_id)
    |> where([mod], mod.is_private == false)
    |> where([mod, class], class.class_id == ^student_class.class_id)
    |> Repo.all()
    
    status = mods |> Enum.map(&insert_mod_action(student_class, &1))
    
    status |> Enum.find({:ok, mods}, &MapErrors.check_tuple(&1))
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
    case Mods.pending_mods_for_student_assignment(assignment) do
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

  defp day_filter(dynamic, %{"class_meet_days" => filter, "or" => "true"}) do
    dynamic([class, period, prof], class.meet_days == ^filter or ^dynamic)
  end
  defp day_filter(dynamic, %{"class_meet_days" => filter}) do
    dynamic([class, period, prof], class.meet_days == ^filter and ^dynamic)
  end
  defp day_filter(dynamic, _), do: dynamic

  # Gets the count of students enrolled in a class.
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

  # Makes sure students have less than @enrollment_limit classes.
  defp check_enrollment_limit(%Ecto.Changeset{valid?: true} = changeset, student_id) do
    class_count = from(classes in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> Repo.aggregate(:count, :id)

    case class_count < @enrollment_limit do
      true -> changeset
      false -> changeset |> Ecto.Changeset.add_error(:student_class, "Enrollment limit reached")
    end
  end
  defp check_enrollment_limit(changeset, _student_id), do: changeset

  defp enroll(student_id, class_id, params, opts \\ []) do
    Logger.info("Enrolling class: " <> class_id <> " student: " <> student_id)
    changeset = StudentClass.changeset(%StudentClass{}, params)
    |> add_enrolled_by(opts)
    |> check_enrollment_limit(student_id)
    
    class = Classes.get_class_by_id(class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:student_class, changeset)
    |> Ecto.Multi.run(:enrollment_link, &generate_enrollment_link(&1.student_class))
    |> Ecto.Multi.run(:status, &Classes.check_status(class, &1))
    |> Ecto.Multi.run(:student_assignments, &StudentAssignments.insert_assignments(&1))
    |> Ecto.Multi.run(:mods, &add_public_mods(&1))
    |> Ecto.Multi.run(:auto_approve, &auto_approve_mods(&1))
    
    case multi |> Repo.transaction() do
      {:ok, trans} -> 
        {:ok, StudentClasses.get_student_class_by_id(trans.student_class.id)}
      error -> error
    end
  end

  defp enroll_in_dropped_class(item) do
    item
    |> Ecto.Changeset.change(%{is_dropped: false})
    |> check_enrollment_limit(item.student_id)
    |> Repo.update()
  end
end
