defmodule Skoller.Students do
  @moduledoc """
  The Students context.
  """
  
  alias Skoller.Repo
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Classes.Class
  alias Skoller.Schools.School
  alias Skoller.Students.Student
  alias Skoller.ClassStatuses.Status
  alias Skoller.Professors.Professor
  alias Skoller.Periods.ClassPeriod
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Mods
  alias Skoller.Students.FieldOfStudy, as: StudentField
  alias Skoller.FieldsOfStudy.FieldOfStudy
  alias Skoller.StudentAssignments
  alias Skoller.Classes.Schools
  alias Skoller.Classes.Docs
  alias Skoller.EnrolledStudents
  alias Skoller.StudentClasses.EnrollmentLinks

  import Ecto.Query

  require Logger

  @community_threshold 2

  @doc """
  Gets a student by id.

  ## Returns
  `Skoller.Students.Student` or `Ecto.NoResultsError`
  """
  def get_student_by_id!(student_id) do
    Repo.get!(Student, student_id)
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
    |> join(:inner, [c], cs in subquery(Schools.get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> join(:inner, [c, cs], d in subquery(Docs.classes_with_syllabus_subquery()), d.class_id == c.id)
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
    * `Skoller.ClassStatuses.Status` :id
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
    from(sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)))
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
    from(sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()))
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
    |> join(:inner, [s], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery(params)), sc.student_id == s.id)
    |> join(:inner, [s, sc], sfc in subquery(Schools.get_school_from_class_subquery(params)), sfc.class_id == sc.class_id)
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
    link = EnrollmentLinks.generate_link(id)
    
    student
    |> Ecto.Changeset.change(%{enrollment_link: link})
    |> Repo.update()
  end
  def generate_student_link(_student), do: {:ok, nil}

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
end
