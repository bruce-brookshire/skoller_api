defmodule ClassnavapiWeb.Helpers.AssignmentHelper do
  
  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class

  import Ecto.Query

  def insert_student_assignments(%{student_class: %StudentClass{} = student_class}) do
    assignments = get_assignments(%{class_id: student_class.class_id})
    case assignments do
      [] -> {:ok, nil}
      _ -> convert_and_insert(assignments, student_class)
    end
  end

  def get_assignments(%StudentClass{id: id}) do
    query = (from assign in StudentAssignment)
    query
    |> where([assign], assign.student_class_id == ^id)
    |> Repo.all()
  end

  def get_assignments(%{class_id: class_id}) do
    query = (from assign in Assignment)
    query
    |> where([assign], assign.class_id == ^class_id)
    |> Repo.all()
  end

  defp convert_and_insert(assignments, %StudentClass{} = student_class) do
    assignments
    |> convert_assignments(student_class)
    |> insert_assignments()
    
    inserted = student_class
    |> get_assignments

    case inserted do
      [] -> {:error, %{student_class: "Student Assignments not inserted"}}
      _ -> {:ok, inserted}
    end
  end

  defp insert_assignments(enumerable) do
    enumerable
    |> Enum.each(&Repo.insert!(&1))
  end

  defp convert_assignments(enumerable, %StudentClass{} = student_class) do
    enumerable |> Enum.map(&convert_assignment(&1, student_class))
  end

  defp convert_assignment(%Assignment{} = assign, %StudentClass{id: id}) do
    %StudentAssignment{
      name: assign.name,
      weight_id: assign.weight_id,
      assignment_id: assign.id,
      student_class_id: id,
      due: assign.due
    }
  end
end