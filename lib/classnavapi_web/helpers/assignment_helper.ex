defmodule ClassnavapiWeb.Helpers.AssignmentHelper do
  
  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.Assignment

  import Ecto.Query

  @moduledoc """
  
  Contains helper functions for inserting student assignments on enroll and assignment creation.

  """

  def insert_student_assignments(%{student_class: %StudentClass{} = student_class}) do
    assignments = get_assignments(%{class_id: student_class.class_id})
    case assignments do
      [] -> {:ok, nil}
      _ -> convert_and_insert(assignments, student_class)
    end
  end

  def insert_student_assignments(%{assignment: %Assignment{} = assignment}) do
    students = get_students(%{class_id: assignment.class_id})
    case students do
      [] -> {:ok, nil}
      _ -> convert_and_insert(assignment, students)
    end
  end

  def update_student_assignments(%{assignment: %Assignment{} = assignment}) do
    students = get_students(%{class_id: assignment.class_id})
    case students do
      [] -> {:ok, nil}
      _ -> convert_and_update(assignment, students)
    end
  end

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

  def convert_assignment(%Assignment{} = assign, %StudentClass{id: id}) do
    %StudentAssignment{
      name: assign.name,
      weight_id: assign.weight_id,
      assignment_id: assign.id,
      student_class_id: id,
      due: assign.due
    }
  end

  defp get_students(%{class_id: class_id}) do
    Repo.all(from sc in StudentClass, where: sc.class_id == ^class_id)
  end

  defp convert_and_insert(assignment, student_class) do
    assignment
    |> convert_assignments(student_class)
    |> insert_assignments()

    inserted = get_inserted(student_class, assignment)

    case inserted do
      [] -> {:error, %{student_class: "Student Assignments not inserted"}}
      _ -> {:ok, inserted}
    end
  end

  defp convert_and_update(assignment, student_class) do
    assignment
    |> convert_assignments(student_class)
    |> Enum.each(&update_assignment(&1))

    updated = get_inserted(student_class, assignment)

    case updated do
      [] -> {:error, %{student_class: "Student Assignments not updated"}}
      _ -> {:ok, updated}
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

  defp insert_assignments(enumerable) do
    enumerable
    |> Enum.each(&Repo.insert!(&1))
  end

  defp update_assignment(student_assignment) do
    case Repo.get_by(StudentAssignment, assignment_id: student_assignment.assignment_id, student_class_id: student_assignment.student_class_id) do
      nil -> :ok
      assign_old -> StudentAssignment.changeset_update_auto(assign_old, %{name: student_assignment.name,
                                                                      weight_id: student_assignment.weight_id,
                                                                      due: student_assignment.due}) 
                    |> Repo.update
    end
  end

  defp convert_assignments(enumerable, %StudentClass{} = student_class) do
    enumerable |> Enum.map(&convert_assignment(&1, student_class))
  end

  defp convert_assignments(%Assignment{} = assign, enumerable) do
    enumerable |> Enum.map(&convert_assignment(assign, &1))
  end
end