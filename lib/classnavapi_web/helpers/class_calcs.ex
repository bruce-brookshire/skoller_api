defmodule ClassnavapiWeb.Helpers.ClassCalcs do
  
  alias Classnavapi.Repo
  alias Classnavapi.Class
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.Weight
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.Status
  alias ClassnavapiWeb.Helpers.AssignmentHelper

  import Ecto.Query

  @ghost_status "Ghost"
  @first_half "1st Half"
  @second_half "2nd Half"
  @full_term "Full Term"
  @custom "Custom"

  @moduledoc """
  
  Gets enrollment, grades, completion, etc. for controllers.

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

  def get_class_completion(%StudentClass{id: student_class_id} = params) do
    relative_weights = get_relative_weight(params)

    student_class_id
    |> get_completed_assignments()
    |> Enum.reduce(Decimal.new(0), &Decimal.add(get_weight(&1, relative_weights), &2))
  end

  # Gets assignments with relative weights by either StudentAssignment or Assignments based on params.
  def get_assignments_with_relative_weight(%{} = params) do #good.
    assign_weights = get_relative_weight(params)

    params
    |> AssignmentHelper.get_assignments()
    |> Enum.map(&Map.put(&1, :relative_weight, get_weight(&1, assign_weights)))
  end

  def get_enrollment(%{students: _students} = class) do
    class = class |> Repo.preload(:students)
    get_enrolled(class.students)
  end

  def professor_name(class) do
    class = class |> Repo.preload(:professor)
    extract_name(class.professor, is_nil(class.professor))
  end

  def get_class_length(class, class_period) do
    compare_classes(class.class_start == class_period.start_date, class.class_end == class_period.end_date)
  end

  def get_class_length(class) do
    class = class |> Repo.preload(:class_period)
    compare_classes(class.class_start == class.class_period.start_date, class.class_end == class.class_period.end_date)
  end

  def get_class_status(%Class{} = class) do
    class = class |> Repo.preload(:class_status)
    get_status(class)
  end
  def get_class_status(%Status{} = class_status) do
    get_status(%{class_status: class_status})
  end

  defp get_relative_weight(%{} = params) do #good
    assign_count = params
                  |> relative_weight_subquery()
                  |> Repo.all()

    weight_sum = assign_count 
                  |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))

    assign_count
    |> Enum.map(&Map.put(&1, :relative, calc_relative_weight(&1, weight_sum)))
  end

  defp relative_weight_subquery(%StudentClass{id: id}) do #good
    query = (from assign in StudentAssignment)
    query
    |> join(:left, [assign], weight in Weight, assign.weight_id == weight.id)
    |> where([assign], assign.student_class_id == ^id)
    |> group_by([assign, weight], [assign.weight_id, weight.weight])
    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id, weight: weight.weight})
  end

  defp relative_weight_subquery(%{class_id: class_id}) do
    query = (from assign in Assignment)
    query
    |> join(:left, [assign], weight in Weight, assign.weight_id == weight.id)
    |> where([assign], assign.class_id == ^class_id)
    |> where([assign], assign.from_mod == false)
    |> group_by([assign, weight], [assign.weight_id, weight.weight])
    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id, weight: weight.weight})
  end

  defp get_status(%{class_status: %{is_complete: false}, is_ghost: true}), do: @ghost_status
  defp get_status(%{class_status: status}), do: status.name

  defp compare_classes(true, true), do: @full_term
  defp compare_classes(true, false), do: @first_half
  defp compare_classes(false, true), do: @second_half
  defp compare_classes(false, false), do: @custom

  defp extract_name(_, true), do: "None"
  defp extract_name(professor, false) do
      professor.name_last
  end

  defp get_enrolled(nil), do: 0
  defp get_enrolled(students) do
      students 
      |> Enum.count(& &1)
  end

  defp get_weight(%{weight_id: weight_id}, enumerable) do
    enumerable
    |> Enum.find(%{}, & &1.weight_id == weight_id)
    |> Map.get(:relative, Decimal.new(0))
  end

  defp get_completed_assignments(student_class_id) do
    query = from(assign in StudentAssignment)
    query
        |> where([assign], assign.student_class_id == ^student_class_id)
        |> where([assign], not(is_nil(assign.grade)))
        |> where([assign], not(is_nil(assign.weight_id)))
        |> Repo.all()
  end

  defp calc_relative_weight(%{weight: weight, count: count}, weight_sum) do
    weight
    |> Decimal.div(Decimal.new(count))
    |> Decimal.div(Decimal.new(weight_sum))
  end

end