defmodule Skoller.Classes.Assignments do
  @moduledoc """
  A context module for assignments in classes
  """

  alias Skoller.Repo
  alias Skoller.Assignments.Assignment
  alias Skoller.Weights.Weight

  import Ecto.Query

  @doc """
  Gets a count of assignments for each weight in a class.
  """
  def get_assignment_count_by_weight(class_id) do
    from(w in Weight)
    |> where([w], w.class_id == ^class_id)
    |> join(:left, [w], a in Assignment, a.weight_id == w.id)
    |> group_by([w], w.id)
    |> select([w, a], %{count: count(a.id), weight_id: w.id})
    |> Repo.all()
  end

  @doc """
  Gets a list of assignments for a class that have no weight
  """
  def get_assignments_with_no_weight(class_id) do
    from(a in Assignment)
    |> where([a], is_nil(a.weight_id))
    |> where([a], a.class_id == ^class_id)
    |> Repo.all()
  end
end