defmodule Skoller.StudentAssignments do
  @moduledoc """
  The context module for student assignments.
  """

  alias Skoller.Repo
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Class.Assignment
  alias Skoller.Students
  alias Skoller.Class.Weight

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
   * Passing a `Skoller.StudentClasses.StudentClass` will cause the student to get all assignments for the class.
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

  def get_class_completion(%StudentClass{id: student_class_id} = student_class) do
    relative_weights = get_relative_weight(student_class)

    student_class_id
    |> get_completed_assignments()
    |> Enum.reduce(Decimal.new(0), &Decimal.add(get_weight(&1, relative_weights), &2))
  end

  # Gets assignments with relative weights by either StudentAssignment or Assignments based on params.
  def get_assignments_with_relative_weight(%{} = params) do #good.
    assign_weights = get_relative_weight(params)

    params
    |> get_assignments()
    |> Enum.map(&Map.put(&1, :relative_weight, get_weight(&1, assign_weights)))
  end

  defp get_completed_assignments(student_class_id) do
    query = from(assign in StudentAssignment)
    query
        |> where([assign], assign.student_class_id == ^student_class_id)
        |> where([assign], not(is_nil(assign.grade)))
        |> where([assign], not(is_nil(assign.weight_id)))
        |> Repo.all()
  end

  defp get_weight(%{weight_id: weight_id}, enumerable) do
    enumerable
    |> Enum.find(%{}, & &1.weight_id == weight_id)
    |> Map.get(:relative, Decimal.new(0))
  end

  defp get_relative_weight(%{class_id: class_id} = params) do #good
    assign_count_subq = params
                  |> relative_weight_subquery()

    assign_count = from(w in Weight)
    |> join(:left, [w], s in subquery(assign_count_subq), s.weight_id == w.id)
    |> where([w], w.class_id == ^class_id)
    |> select([w, s], %{weight: w.weight, count: s.count, weight_id: w.id})
    |> Repo.all()
    
    weight_sum = assign_count 
                  |> Enum.filter(& &1.weight != nil)
                  |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))

    assign_count
    |> Enum.map(&Map.put(&1, :relative, calc_relative_weight(&1, weight_sum)))
  end

  defp relative_weight_subquery(%StudentClass{id: id}) do #good
    query = (from assign in StudentAssignment)
    query
    |> join(:inner, [assign], weight in Weight, assign.weight_id == weight.id)
    |> where([assign], assign.student_class_id == ^id)
    |> group_by([assign, weight], [assign.weight_id, weight.weight])
    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id})
  end

  defp relative_weight_subquery(%{class_id: class_id}) do
    query = (from assign in Assignment)
    query
    |> join(:inner, [assign], weight in Weight, assign.weight_id == weight.id)
    |> where([assign], assign.class_id == ^class_id)
    |> where([assign], assign.from_mod == false)
    |> group_by([assign, weight], [assign.weight_id, weight.weight])
    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id})
  end

  defp calc_relative_weight(%{count: nil}, _weight_sum), do: Decimal.new(0)
  defp calc_relative_weight(%{weight: weight, count: count}, weight_sum) do
    weight
    |> Decimal.div(Decimal.new(weight_sum))
    |> Decimal.div(Decimal.new(count))
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