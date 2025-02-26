defmodule Skoller.Mods.Classes do
  @moduledoc """
  A context module for mods and classes
  """

  alias Skoller.Mods.Mod
  alias Skoller.Repo
  alias Skoller.Assignments.Assignment
  alias Skoller.Classes.Class

  import Ecto.Query

  @doc """
  Gets the class from a mod id

  ## Returns
  `Skoller.Classes.Class`, `nil` or raises if more than one.
  """
  def get_class_from_mod_id(mod_id) do
    from(class in Class)
    |> join(:inner, [class], assign in Assignment, on: class.id == assign.class_id)
    |> join(:inner, [class, assign], mod in Mod, on: mod.assignment_id == assign.id)
    |> where([class, assign, mod], mod.id == ^mod_id)
    |> Repo.one()
  end

  @doc """
  Subquery to associate Mods and Classes easily.

  Intended to be used with `Ecto.Query.subquery/1`

  ## Returns
  `Ecto.Query` with `%{class_id: id, mod_id: id}`
  """
  def get_class_from_mod_subquery() do
    from(mod in Mod)
    |> join(:inner, [mod], assign in Assignment, on: mod.assignment_id == assign.id)
    |> select([mod, assign], %{class_id: assign.class_id, mod_id: mod.id})
  end

  def get_count_of_mods_in_classes(mods, classes) do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, on: m.assignment_id == a.id)
    |> where([m, a], a.class_id in ^classes)
    |> where([m], m.id in ^mods)
    |> select([m], count(m.id))
    |> Repo.one()
  end
end