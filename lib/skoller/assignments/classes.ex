defmodule Skoller.Assignments.Classes do
  @moduledoc """
  A context module for class assignments
  """
  use Skoller.Schema

  @doc """
  Gets non mod assignments by class.
  """
  def get_assignments_by_class(class_id) do
    Assignment
    |> where([a], a.class_id == ^class_id)
    |> where([a], not a.from_mod)
    |> Repo.all()
  end
end
