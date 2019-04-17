defmodule Skoller.Assignments.Schools do
  @moduledoc """
    Context module for school assignments
  """

  alias Skoller.Repo
  alias Skoller.Assignments.Assignment
  alias Skoller.Classes.Class
  alias Skoller.Classes.Schools

  import Ecto.Query

  @doc """
  Get all assignments in a school.

  ## Returns
  `[%Skoller.Assignments.Assignment{}]` or `[]`
  """
  def get_school_assignments(school_id) do
    from(a in Assignment)
    |> join(:inner, [a], c in Class, on: c.id == a.class_id)
    |> join(:inner, [a, c], s in subquery(Schools.get_school_from_class_subquery(school_id)), on: c.id == s.class_id)
    |> Repo.all()
  end
end