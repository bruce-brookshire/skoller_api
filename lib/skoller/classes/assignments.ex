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
end