defmodule Skoller.StudentClasses do
  @moduledoc """
  Context module for students in classes.
  """

  alias Skoller.Repo
  alias Skoller.Weights.Weight
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Schools
  alias Skoller.Classes.EditableClasses
  alias Skoller.EnrolledStudents
  alias Skoller.Classes
  alias Skoller.Students
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses
  alias Skoller.StudentAssignments
  alias Skoller.Mods.StudentClasses, as: StudentClassMods
  alias Skoller.StudentClasses.EnrollmentLinks
  alias Skoller.AutoUpdates
  alias Skoller.MapErrors
  alias Skoller.StudentPoints

  import Ecto.Query

  require Logger

  @class_referral_points_name "Class Referral"

  @doc """
  Gets a grade for a student class.

  ## Returns
  `Decimal`
  """
  def get_class_grade(student_class_id) do
    query = from(assign in StudentAssignment)
    student_grades = query
      |> join(:inner, [assign], weight in Weight, weight.id == assign.weight_id)
      |> where([assign], assign.student_class_id == ^student_class_id)
      |> group_by([assign, weight], [assign.weight_id, weight.weight])
      |> select([assign, weight], %{grade: avg(assign.grade), weight_id: assign.weight_id, weight: weight.weight})
      |> Repo.all()
      |> Enum.filter(&not(is_nil(&1.grade)))

    weight_sum = student_grades |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))

    student_grades |> Enum.reduce(Decimal.new(0), &Decimal.add(Decimal.div(Decimal.mult(&1.weight, &1.grade), weight_sum), &2))
  end

  @doc """
  This gets a student class by the class and student id.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `nil`
  """
  def get_student_class_by_student_and_class(class_id, student_id) do
    Repo.get_by(StudentClass, class_id: class_id, student_id: student_id)
  end

  @doc """
  This gets a student class by the student class id.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `nil`
  """
  def get_student_class_by_id(id) do
    Repo.get(StudentClass, id)
  end

  @doc """
  This gets a student class by the student class id.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `Ecto.NoResultsError`
  """
  def get_student_class_by_id!(id) do
    Repo.get!(StudentClass, id)
  end

  @doc """
  Gets most common school from a list of student classes.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or `Ecto.NoResultsError`
  """
  def get_most_common_school([]), do: nil
  def get_most_common_school(student_classes) do
    max = student_classes
    |> Enum.map(&Schools.get_school_from_period(&1.class.class_period_id))
    |> Enum.chunk_by(& &1.id)
    |> Enum.map(& %{school: List.first(&1), count: Enum.count(&1)})
    |> Enum.max_by(& &1.count)
    max.school
  end

  @doc """
  Gets student classes in a class. Includes previously-enrolled students.

  ## Returns
  `[Skoller.StudentClasses.StudentClass]` or `[]`
  """
  def get_studentclasses_by_class(class_id) do
    from(sc in StudentClass)
    |> where([sc], sc.class_id == ^class_id)
    |> Repo.all()
  end

  @doc """
  Gets a student class where the class is editable and the student enrolled.

  ## Returns
  `Skoller.StudentClasses.StudentClass` or raises on no results
  """
  def get_active_student_class_by_ids!(class_id, student_id) do
    from(sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)))
    |> join(:inner, [sc], class in subquery(EditableClasses.get_editable_classes_subquery()), class.id == sc.class_id)
    |> where([sc], sc.class_id == ^class_id)
    |> Repo.one!()
  end

  @doc """
  Generates an enrollment link for a student class that does not have one yet.

  ## Returns
  `{:ok, Skoller.StudentClasses.StudentClass}` or `{:error, Ecto.Changeset}`
  """
  def generate_enrollment_link(%StudentClass{id: id} = student_class) do
    link = EnrollmentLinks.generate_link(id)

    Logger.info("Generating enrollment link " <> to_string(link) <> " for student class: " <> to_string(id))

    student_class
    |> Ecto.Changeset.change(%{enrollment_link: link})
    |> Repo.update()
  end

  @doc """
  Enrolls a student in a class.

  ## Params
   * %{"color" => color}, sets the student class color.

  ## Returns
  `{:ok, Skoller.StudentClasses.StudentClass}` or `{:error, Ecto.Changeset}`
  """
  def enroll_in_class(student_id, class_id, params) do
    case get_student_class_by_student_and_class(class_id, student_id) do
      nil ->
        enroll(student_id, class_id, params)
      %{is_dropped: true} = sc ->
        enroll_in_dropped_class(sc)
      _sc ->
        {:error, nil, %{student_class: "class taken"}, nil}
    end
  end

  @doc false
  def enroll(student_id, class_id, params, opts \\ []) do
    Logger.info("Enrolling class: " <> to_string(class_id) <> " student: " <> to_string(student_id))
    changeset = StudentClass.changeset(%StudentClass{}, params)
    |> add_enrolled_by(opts)
    |> check_enrollment_limit(student_id)
    
    class = Classes.get_class_by_id(class_id) |> Repo.preload(:school)
    student = Students.get_student_by_id!(student_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:student_class, changeset)
    |> Ecto.Multi.run(:enrollment_link, &generate_enrollment_link(&1.student_class))
    |> Ecto.Multi.run(:status, &ClassStatuses.check_status(class, &1))
    |> Ecto.Multi.run(:student_assignments, &StudentAssignments.insert_assignments(&1))
    |> Ecto.Multi.run(:mods, &StudentClassMods.add_public_mods_for_student_class(&1))
    |> Ecto.Multi.run(:auto_approve, &auto_approve_mods(&1))
    |> Ecto.Multi.run(:points, &add_points_to_student(&1.student_class))
    |> Ecto.Multi.run(:primary_school, fn _trans -> Students.conditional_primary_school_set(student, class.school.id) end)

    case multi |> Repo.transaction() do
      {:ok, trans} -> 
        {:ok, get_student_class_by_id(trans.student_class.id)}
      error -> error
    end
  end

  defp enroll_in_dropped_class(item) do
    item
    |> Ecto.Changeset.change(%{is_dropped: false})
    |> check_enrollment_limit(item.student_id)
    |> Repo.update()
  end

  # Makes sure students have less than allowed limit of non dropped classes.
  defp check_enrollment_limit(%Ecto.Changeset{valid?: true} = changeset, student_id) do
    case EnrolledStudents.check_enrollment_limit_for_student(student_id) do
      true -> changeset
      false -> changeset |> Ecto.Changeset.add_error(:student_class, "Enrollment limit reached")
    end
  end
  defp check_enrollment_limit(changeset, _student_id), do: changeset

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

  defp auto_approve_mods(%{mods: mods}) do
    Logger.info("Processing mod auto updates")
    status = mods
    |> Enum.map(&AutoUpdates.process_auto_update(&1))

    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
  defp auto_approve_mods(_params), do: {:ok, nil}

  defp add_points_to_student(%{enrolled_by: enrolled_by}) when not(is_nil(enrolled_by)) do
    sc = get_student_class_by_id!(enrolled_by)

    sc.student_id
    |> StudentPoints.add_points_to_student(@class_referral_points_name)
  end
  defp add_points_to_student(_student_class), do: {:ok, nil}
end