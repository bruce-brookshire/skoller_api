defmodule Skoller.Assignments do
  @moduledoc """
  Context module for assignments
  """

  alias Skoller.Repo
  alias Skoller.Assignments.Assignment
  alias Skoller.StudentAssignments
  alias Skoller.Classes.Weights

  @doc """
  Gets an assignment by id.

  ## Returns
  `Skoller.Assignments.Assignment` or `Ecto.NoResultsError`
  """
  def get_assignment_by_id!(assignment_id) do
    Repo.get!(Assignment, assignment_id)
  end

  @doc """
  Gets an assignment by id.

  ## Returns
  `Skoller.Assignments.Assignment` or `nil`
  """
  def get_assignment_by_id(assignment_id) do
    Repo.get(Assignment, assignment_id)
  end

  @doc """
    Creates an assignment for a class.

    Returns the student assignments created due to the new assignment.

    ## Returns
    `%{assignment: Skoller.Assignments.Assignment, student_assignments: [Skoller.StudentAssignments.StudentAssignment]}`
  """
  def create_assignment(class_id, user_id, params) do
    changeset = %Assignment{}
      |> Assignment.changeset(params)
      |> check_weight_id(params)
      |> validate_class_weight(class_id)
      |> Ecto.Changeset.change(%{created_by: user_id, updated_by: user_id, created_on: params["created_on"]})

    Ecto.Multi.new
    |> Ecto.Multi.insert(:assignment, changeset)
    |> Ecto.Multi.run(:student_assignments, fn (_, changes) -> StudentAssignments.insert_assignments(changes) end)
    |> Repo.transaction()
  end

  @doc """
    Updates an assignment for a class.

    Returns the student assignments created due to the updated assignment.

    ## Returns
    `%{assignment: Skoller.Assignments.Assignment, student_assignments: [Skoller.StudentAssignments.StudentAssignment]}`
  """
  def update_assignment(id, user_id, params) do
    assign_old = get_assignment_by_id!(id)
    changeset = assign_old
      |> Assignment.changeset(params)
      |> check_weight_id(params)
      |> validate_class_weight(assign_old.class_id)
      |> Ecto.Changeset.change(%{updated_by: user_id})

    Ecto.Multi.new
    |> Ecto.Multi.update(:assignment, changeset)
    |> Ecto.Multi.run(:student_assignments, fn (_, changes) -> StudentAssignments.update_assignments(changes) end)
    |> Repo.transaction()
  end

  @doc """
  Deletes an assignment by id.

  ## Returns
  `{:ok, assignment}` or `{:error, changeset}`
  """
  def delete_assignment(id) do
    id
    |> get_assignment_by_id!()
    |> Repo.delete()
  end

  defp check_weight_id(changeset, %{"weight_id" => nil}) do
    changeset |> Ecto.Changeset.force_change(:weight_id, nil)
  end
  defp check_weight_id(changeset, _params), do: changeset

  defp validate_class_weight(%Ecto.Changeset{changes: %{weight_id: nil}} = changeset, class_id) do
    weights = Weights.get_class_weights(class_id)

    case weights do
      [] -> changeset
      _ -> changeset |> Ecto.Changeset.add_error(:weight_id, "Weight can't be null when weights exist.")
    end
  end
  defp validate_class_weight(%Ecto.Changeset{changes: %{class_id: class_id, weight_id: weight_id}, valid?: true} = changeset, _class_id) do
    case Weights.get_class_weight_by_ids(class_id, weight_id) do
      nil -> changeset |> Ecto.Changeset.add_error(:weight_id, "Weight class combination invalid")
      _ -> changeset
    end
  end
  defp validate_class_weight(changeset, _class_id), do: changeset
end
