defmodule Skoller.Students do
  @moduledoc """
  The Students context.
  """
  
  alias Skoller.Repo
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Schools.School
  alias Skoller.Students.Student
  alias Skoller.Students.FieldOfStudy, as: StudentField
  alias Skoller.FieldsOfStudy.FieldOfStudy
  alias Skoller.Classes.Schools
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
end
