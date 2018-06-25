defmodule Skoller.StudentAssignments do
  @moduledoc """
  The context module for student assignments.
  """

  alias Skoller.Repo
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Class.StudentClass
  alias Skoller.Class.Assignment
  alias Skoller.Students

  import Ecto.Query

  @doc """
  Gets a student assignment by assignment id and student class id.

  ## Returns
  `Skoller.StudentAssignments.StudentAssignment` or `nil`
  """
  def get_assignment_by_ids(assignment_id, student_class_id) do
    Repo.get_by(StudentAssignment, assignment_id: assignment_id, student_class_id: student_class_id)
  end

  @doc """
  Inserts assignments for all students in the class, or inserts all class assignments for a student.

  ## Behavior
   * Passing a `Skoller.Class.StudentClass` will cause the student to get all assignments for the class.
   * Passing a `Skoller.Class.Assignment` will cause all students to get the assignment.

  ## Returns
  `{:ok, [Skoller.StudentAssignments.StudentAssignment]}` or `{:ok, nil}` if there are no students or assignments
  or `{:error, %{student_class: "Student Assignments not inserted"}}` if something went wrong.
  """
  # TODO: I made this when I first started Elixir. This is absolutely awful.
  # It needs to be split out depending on what is calling it, and likely into different modules altogether.
  def insert_assignments(student_class_or_assignment_struct)
  def insert_assignments(%{student_class: %StudentClass{} = student_class}) do
    case get_assignments(%{class_id: student_class.class_id}) do
      [] -> {:ok, nil}
      assignments -> convert_and_insert(assignments, student_class)
    end
  end
  def insert_assignments(%{assignment: %Assignment{} = assignment}) do
    case Students.get_students_by_class(assignment.class_id) do
      [] -> {:ok, nil}
      students -> convert_and_insert(assignment, students)
    end
  end

  @doc """
  Updates student assignments when a class assignment is changed.

  ## Behavior
   * This will currently overwrite all mods a student has accepted and not reset the mods.

  ## Returns
  `{:ok, [Skoller.StudentAssignments.StudentAssignment]}` or `{:ok, nil}` if there are no students or assignments
  or `{:error, %{student_class: "Student Assignments not updated"}}` if something went wrong.
  """
  def update_assignments(%{assignment: %Assignment{} = assignment}) do
    case Students.get_students_by_class(assignment.class_id) do
      [] -> {:ok, nil}
      students -> convert_and_update(assignment, students)
    end
  end

  @doc """
  Converts an assignment into a student assignment.

  ## Returns
  `Skoller.StudentAssignments.StudentAssignment`
  """
  def convert_assignment(%Assignment{} = assignment, %StudentClass{id: id}) do
    %StudentAssignment{
      name: assignment.name,
      weight_id: assignment.weight_id,
      assignment_id: assignment.id,
      student_class_id: id,
      due: assignment.due
    }
  end

  @doc """
  Gets a student's assignments, gets student's assignments by id, or gets class assignments

  ## Behavior
   * If passed a student class, gets all student assignments for that student class.
   * If passed an assignment, gets all student assignments for that assignment.
   * If passed a map containing `%{class_id: class_id}`, gets all assignments for that class.

  ## Returns
  `[Skoller.StudentAssignments.StudentAssignment]`, `[Skoller.Class.Assignment]`, or `[]`
  """
  # TODO: I made this when I first started Elixir. This is absolutely awful.
  # This is the single worst piece of code.
  # Anyways. This needs help. This should not do 3 different things.
  def get_assignments(%StudentClass{id: id}) do
    query = (from assign in StudentAssignment)
    query
    |> where([assign], assign.student_class_id == ^id)
    |> Repo.all()
  end
  def get_assignments(%Assignment{id: id}) do
    query = (from assign in StudentAssignment)
    query
    |> where([assign], assign.assignment_id == ^id)
    |> Repo.all()
  end
  def get_assignments(%{class_id: class_id}) do
    query = (from assign in Assignment)
    query
    |> where([assign], assign.class_id == ^class_id)
    |> where([assign], assign.from_mod == false)
    |> Repo.all()
  end

  defp convert_and_insert(assignment, student_class) do
    assignment
    |> convert_assignments(student_class)
    |> insert()

    case get_inserted(student_class, assignment) do
      [] -> {:error, %{student_class: "Student Assignments not inserted"}}
      inserted -> {:ok, inserted}
    end
  end

  #TODO: Bug here. Mods need to be handled. See Trello
  # Likely bug: in Skoller.StudentAssignments.convert_and_update/2, mods not being considered.
  defp convert_and_update(assignment, student_class) do
    assignment
    |> convert_assignments(student_class)
    |> Enum.each(&update_assignment(&1))

    case get_inserted(student_class, assignment) do
      [] -> {:error, %{student_class: "Student Assignments not updated"}}
      updated -> {:ok, updated}
    end
  end

  defp get_inserted(%StudentClass{} = student_class, _enumerable) do
    student_class
    |> get_assignments
  end

  defp get_inserted(_enumerable, %Assignment{} = assignment) do
    assignment
    |> get_assignments
  end

  defp convert_assignments(enumerable, %StudentClass{} = student_class) do
    enumerable |> Enum.map(&convert_assignment(&1, student_class))
  end

  defp convert_assignments(%Assignment{} = assign, enumerable) do
    enumerable |> Enum.map(&convert_assignment(assign, &1))
  end

  defp insert(enumerable) do
    enumerable
    |> Enum.each(&Repo.insert!(&1))
  end

  defp update_assignment(student_assignment) do
    case get_assignment_by_ids(student_assignment.assignment_id, student_assignment.student_assignment_id) do
      nil -> :ok
      assign_old -> StudentAssignment.changeset_update_auto(assign_old, %{name: student_assignment.name,
                                                                      weight_id: student_assignment.weight_id,
                                                                      due: student_assignment.due}) 
                    |> Repo.update
    end
  end
end