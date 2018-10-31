defmodule Skoller.Assignments.Classes do
  @moduledoc """
  A context module for class assignments
  """

  alias Skoller.Repo
  alias Skoller.Assignments.Assignment

  import Ecto.Query

  @doc """
  Gets non mod assignments by class.
  """
  def get_assignments_by_class(class_id) do
    from(a in Assignment)
    |> where([a], a.class_id == ^class_id)
    |> where([assign], assign.from_mod == false)
    |> Repo.all()
  end
end