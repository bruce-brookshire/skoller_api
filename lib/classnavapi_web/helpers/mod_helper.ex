defmodule ClassnavapiWeb.Helpers.ModHelper do
  use ClassnavapiWeb, :controller

  @moduledoc """
  
  Helper for inserting mods.

  """

  alias Classnavapi.Class.Assignment
  alias Classnavapi.Assignment.Mod
  alias Classnavapi.Repo

  @new_assignment_mod 400

  def insert_new_mod(%{assignment: %Assignment{} = assignment}, params) do
    mod = %{
      data: %{
        assignment: %{
          name: assignment.name,
          due: assignment.due,
          class_id: assignment.class_id,
          weight_id: assignment.weight_id,
          id: assignment.id
        }
      },
      assignment_mod_type_id: @new_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: params["student_id"],
      assignment_id: assignment.id
    }
    changeset = Mod.changeset(%Mod{}, mod)
    Repo.insert(changeset)
  end

  defp is_private(nil), do: false
  defp is_private(value), do: value
end