defmodule Skoller.Classes.Assignments do
  @moduledoc """
  A context module for class assignments
  """

  alias Skoller.Repo
  alias Skoller.Assignments.Assignment
  
  import Ecto.Query

  @doc """
  Gets all assignments for a class.

  Returns `[Skoller.Assignments.Assignment]` or `[]`
  """
  def all(class_id) do
    from(w in Assignment)
    |> where([w], w.class_id == ^class_id)
    |> Repo.all
  end
end