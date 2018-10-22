defmodule Skoller.AdminClasses do
  @moduledoc """
  A context module for class administration
  """

  alias Skoller.Repo
  alias Skoller.Classes
  alias Skoller.Mods
  alias Skoller.Classes.Note
  alias Skoller.StudentClasses

  @doc """
    Gets a `Skoller.Classes.Class` by id with `Skoller.Weights.Weight`, `Skoller.Classes.Note`,
    `Skoller.Students.Student`, Skoller.Assignments.Assignment`
  """
  def get_full_class_by_id!(id) do
    Classes.get_full_class_by_id!(id)
    |> Repo.preload(:notes)
    |> Map.put(:students, StudentClasses.get_studentclasses_by_class(id))
    |> Map.put(:assignments, Mods.get_mod_assignments_by_class(id))
  end

  @doc """
    Adds a note to a class, and then returns `Skoller.AdminClasses.get_full_class_by_id/1`
  """
  def create_note(class_id, params) do
    note = %Note{}
    |> Note.changeset(params)
    |> Repo.insert()

    case note do
      {:ok, _note} -> {:ok, get_full_class_by_id!(class_id)}
      {:error, _error} -> note
    end
  end
end