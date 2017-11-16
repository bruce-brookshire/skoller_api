defmodule ClassnavapiWeb.Helpers.ModHelper do
  use ClassnavapiWeb, :controller

  @moduledoc """
  
  Helper for inserting mods.

  """

  alias Classnavapi.Class.Assignment
  alias Classnavapi.Assignment.Mod
  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentClass

  @name_assignment_mod 100
  @weight_assignment_mod 200
  @due_assignment_mod 300
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
    mod |> insert_mod()
  end

  def insert_update_mod(%{student_assignment: student_assignment}, %Ecto.Changeset{changes: changes}, params) do
    student_assignment = student_assignment |> Repo.preload(:assignment)
    status = changes |> Enum.map(&get_changes(&1, student_assignment, params))
    status |> Enum.find({:ok, status}, &errors(&1))
  end

  defp errors(tuple) do
    case tuple do
      {:error, val} -> true
      _ -> false
    end
  end

  #If there are no changes, this function will not be hit at all.
  defp get_changes(tuple, %{} = student_assignment, params) do
    case tuple do
      {:weight_id, weight_id} -> check_change(:weight, weight_id, student_assignment, params)
      {:due, due} -> check_change(:due, due, student_assignment, params)
      {:name, name} -> check_change(:name, name, student_assignment, params)
    end
  end

  defp check_change(:weight, weight_id, %{assignment: %{weight_id: old_weight_id}} = student_assignment, params) do
    case old_weight_id == weight_id do
      false -> weight_id |> insert_weight_mod(student_assignment, params)
      true -> nil
    end
  end

  defp check_change(:due, due, %{assignment: %{due: old_due}} = student_assignment, params) do
    case old_due == due do
      false -> due |> insert_due_mod(student_assignment, params)
      true -> nil
    end
  end

  defp check_change(:name, name, %{assignment: %{name: old_name}} = student_assignment, params) do
    case old_name == name do
      false -> name |> insert_name_mod(student_assignment, params)
      true -> nil
    end
  end

  defp insert_weight_mod(weight_id, %{} = student_assignment, params) do
    student = Repo.get!(StudentClass, student_assignment.student_class_id)

    mod = %{
      data: %{
        weight_id: weight_id
      },
      assignment_mod_type_id: @weight_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student.id,
      assignment_id: student_assignment.assignment.id
    }
    mod |> insert_mod()
  end

  defp insert_due_mod(due, %{} = student_assignment, params) do
    student = Repo.get!(StudentClass, student_assignment.student_class_id)

    mod = %{
      data: %{
        due: due
      },
      assignment_mod_type_id: @due_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student.id,
      assignment_id: student_assignment.assignment.id
    }
    mod |> insert_mod()
  end

  defp insert_name_mod(name, %{} = student_assignment, params) do
    student = Repo.get!(StudentClass, student_assignment.student_class_id)

    mod = %{
      data: %{
        name: name
      },
      assignment_mod_type_id: @name_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student.id,
      assignment_id: student_assignment.assignment.id
    }
    mod |> insert_mod()
  end

  defp insert_mod(mod) do
    changeset = Mod.changeset(%Mod{}, mod)
    Repo.insert(changeset)
  end

  defp is_private(nil), do: false
  defp is_private(value), do: value
end