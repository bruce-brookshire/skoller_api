defmodule Skoller.EnrolledStudents do
  @moduledoc """
  A context module based on enrolled students
  """

  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Repo

  import Ecto.Query

  @enrollment_limit 15

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
end