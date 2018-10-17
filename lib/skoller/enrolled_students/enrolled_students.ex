defmodule Skoller.EnrolledStudents do
  @moduledoc """
  A context module based on enrolled students
  """

  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Repo
  alias Skoller.Classes.Schools
  alias Skoller.Students.Student
  alias Skoller.Classes.Class

  import Ecto.Query

  @enrollment_limit 15

  @doc """
  Gets students in a class.

  ## Returns
  `[Skoller.Students.Student]` or `[]`
  """
  def get_students_by_class(class_id) do
    from(s in Student)
    |> join(:inner, [s], sc in subquery(get_enrollment_by_class_id_subquery(class_id)), s.id == sc.student_id)
    |> Repo.all()
  end

  @doc """
  Subquery that gets enrolled students in a class

  Returns subquery with `Skoller.StudentClasses.StudentClass`.
  """
  def enrolled_student_class_subquery() do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
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
  Returns `Skoller.StudentClasses.StudentClass` with `Skoller.Classes.Class` that a `Skoller.Students.Student` currently has.

  ## Examples

      iex> val = Skoller.EnrolledStudents.get_enrolled_classes_by_student_id(1)
      [%Skoller.StudentClasses.StudentClass{class: %Skoller.Classes.Class{}}]

  """
  def get_enrolled_classes_by_student_id(student_id) do
    #TODO: Filter ClassPeriod
    from(classes in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> Repo.all()
    |> Repo.preload(:class)
  end

  @doc """
  Checks a student's number of currently enrolled classes.

  ## Returns
  `true` if a student can enroll in more classes, otherwise `false`
  """
  def check_enrollment_limit_for_student(student_id) do
    class_count = from(classes in subquery(get_enrolled_classes_by_student_id_subquery(student_id)))
    |> Repo.aggregate(:count, :id)

    class_count < @enrollment_limit
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
  Returns a subquery that provides a list of `Skoller.StudentClasses.StudentClass` where the classes are not dropped by `Skoller.Schools.School`

  """
  def get_enrolled_student_classes_subquery(params \\ %{}) do
    from(sc in StudentClass)
    |> join(:inner, [sc], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == sc.class_id)
    |> where([sc], sc.is_dropped == false)
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
    |> join(:inner, [s, sc], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == sc.class_id)
    |> where([s, sc], sc.is_dropped == false)
    |> distinct([s], s.id)
  end
  def get_student_subquery(_params) do
    from(s in Student)
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
  Gets the count of students enrolled in a class.
  """
  def count_subquery() do
    from(c in Class)
    |> join(:left, [c], sc in StudentClass, c.id == sc.class_id)
    |> where([c, sc], sc.is_dropped == false)
    |> group_by([c, sc], c.id)
    |> select([c, sc], %{class_id: c.id, count: count(sc.id)})
  end
end