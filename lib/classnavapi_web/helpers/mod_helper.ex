defmodule ClassnavapiWeb.Helpers.ModHelper do
  use ClassnavapiWeb, :controller

  @moduledoc """
  
  Helper for inserting mods.

  """

  alias Classnavapi.Class.Assignment
  alias Classnavapi.Assignment.Mod
  alias Classnavapi.Assignment.Mod.Action
  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.StudentAssignment

  import Ecto.Query

  @name_assignment_mod 100
  @weight_assignment_mod 200
  @due_assignment_mod 300
  @new_assignment_mod 400
  @delete_assignment_mod 500

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
    existing_mod = mod |> find_mod()
    cond do
      existing_mod == [] and assignment.from_mod == true ->
        # The assignment is not an original assignment, and needs a mod.
        mod 
        |> insert_mod_and_action(params["student_id"])
      existing_mod == [] and assignment.from_mod == false -> 
        # The assignment is original, and should not have a mod.
        {:ok, existing_mod}
      existing_mod.is_private == true and mod.is_private == false ->
        # The assignment has a mod that needs to be published.
        existing_mod |> publish_mod_and_action(params["student_id"])
      true -> 
        # The assignment has a mod already, and needs no changes
        existing_mod |> add_mod_action(params["student_id"])
    end
  end

  def insert_update_mod(%{student_assignment: student_assignment}, %Ecto.Changeset{changes: changes}, params) do
    student_assignment = student_assignment |> Repo.preload(:assignment)
    status = changes |> Enum.map(&get_changes(&1, student_assignment, params))
    status |> Enum.find({:ok, status}, &errors(&1))
  end

  def insert_delete_mod(%{student_assignment: student_assignment}, params) do
    student = Repo.get!(StudentClass, student_assignment.student_class_id)

    mod = %{
      data: %{},
      assignment_mod_type_id: @delete_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student.id,
      assignment_id: student_assignment.assignment_id
    }

    existing_mod = mod |> find_mod()
    cond do
      existing_mod == [] ->
        # No current mod.
        mod |> insert_mod_and_action(student)
      existing_mod.is_private == true and mod.is_private == false ->
        # The assignment has a mod that needs to be published.
        existing_mod |> publish_mod_and_action(student)
      true -> 
        # The assignment has a mod already, and needs no changes
        existing_mod |> add_mod_action(student)
    end
  end

  def apply_mod(%Mod{} = mod, %StudentClass{} = student_class) do
    case mod.assignment_mod_type_id do
      @delete_assignment_mod -> apply_delete_mod(mod, student_class)
      @new_assignment_mod -> apply_new_mod(mod, student_class)
      _ -> apply_change_mod(mod, student_class)
    end
  end

  defp apply_delete_mod(%Mod{} = mod, %StudentClass{id: id}) do
    student_assignment = Repo.get_by!(StudentAssignment, assignment_id: mod.assignment_id, student_class_id: id)

    Ecto.Multi.new
    |> Ecto.Multi.delete(:student_assignment, student_assignment)
    |> Ecto.Multi.run(:mod_action, &add_mod_action(&1.student_assignment, mod))
  end

  defp apply_new_mod(%Mod{} = mod, %StudentClass{} = student_class) do

  end

  defp apply_change_mod(%Mod{} = mod, %StudentClass{} = student_class) do
    
  end

  defp errors(tuple) do
    case tuple do
      {:error, _val} -> true
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
    case Date.compare(old_due, due) do
      :eq -> nil
      _ -> due |> insert_due_mod(student_assignment, params)
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
    
    existing_mod = mod |> find_mod()
    cond do
      existing_mod == [] -> mod |> insert_mod_and_action(student)
      existing_mod.is_private == true and mod.is_private == false -> existing_mod |> publish_mod_and_action(student)
      true ->  existing_mod |> add_mod_action(student)
    end
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

    existing_mod = mod |> find_mod()
    cond do
      existing_mod == [] -> mod |> insert_mod_and_action(student)
      existing_mod.is_private == true and mod.is_private == false -> existing_mod |> publish_mod_and_action(student)
      true ->  existing_mod |> add_mod_action(student)
    end
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

    existing_mod = mod |> find_mod()
    cond do
      existing_mod == [] -> mod |> insert_mod_and_action(student)
      existing_mod.is_private == true and mod.is_private == false -> existing_mod |> publish_mod_and_action(student)
      true ->  existing_mod |> add_mod_action(student)
    end
  end
  
  defp find_mod(mod) do
    mod = from(mod in Mod)
    |> where([mod], mod.assignment_id == ^mod.assignment_id)
    |> where([mod], mod.data == ^mod.data)
    |> Repo.all()
    |> List.first()
    case mod do
      nil -> []
      mod -> mod
    end
  end

  defp add_mod_action(%StudentAssignment{student_class_id: id}, %Mod{} = mod) do
    Repo.insert(%Action{assignment_modification_id: mod.id, student_class_id: id, is_accepted: true})
  end

  defp add_mod_action(%Mod{} = mod, %StudentClass{id: id}) do
    Repo.insert(%Action{assignment_modification_id: mod.id, student_class_id: id, is_accepted: true})
  end

  defp add_mod_action(%Mod{} = mod, student_id) do
    mod = mod |> Repo.preload(:assignment)
    student_class = Repo.get_by(StudentClass, class_id: mod.assignment.class_id, student_id: student_id)

    mod = mod
          |> insert_mod_action(student_class)
  end

  defp insert_mod_action(%Mod{is_private: false} = mod, %StudentClass{} = student_class) do
    query = from(sc in StudentClass)
    |> join(:left, [sc], act in Action, sc.id == act.student_class_id)
    |> where([sc], sc.class_id == ^student_class.class_id and sc.id != ^student_class.id)
    |> where([sc, act], is_nil(act.is_accepted))
    |> Repo.all()

    status = query |> Enum.map(&Repo.insert(%Action{assignment_modification_id: mod.id, student_class_id: &1.id, is_accepted: nil}))
    case status |> Enum.find({:ok, status}, &errors(&1)) do
      {:ok, _} -> Repo.insert(%Action{assignment_modification_id: mod.id, student_class_id: student_class.id, is_accepted: true})
      {:error, val} -> {:error, val}
    end
  end

  defp insert_mod_action(%Mod{is_private: true} = mod, %StudentClass{id: id}) do
    Repo.insert(%Action{assignment_modification_id: mod.id, student_class_id: id, is_accepted: true})
  end

  defp insert_mod(mod) do
    changeset = Mod.changeset(%Mod{}, mod)
    Repo.insert(changeset)
  end

  defp publish_mod(mod) do
    changeset = Mod.changeset(mod, %{is_private: false})
    Repo.update(changeset)
  end

  defp is_private(nil), do: false
  defp is_private(value), do: value

  defp insert_mod_and_action(mod, student_class_or_student_id) do
    mod = mod 
    |> insert_mod()
    case mod do
      {:ok, mod} -> mod |> add_mod_action(student_class_or_student_id)
      {:error, val} -> {:error, val}
    end
  end

  defp publish_mod_and_action(mod, student_class_or_student_id) do
    mod = mod 
    |> publish_mod()
    case mod do
      {:ok, mod} -> mod |> add_mod_action(student_class_or_student_id)
      {:error, val} -> {:error, val}
    end
  end
end