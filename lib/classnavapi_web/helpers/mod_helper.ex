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
  alias ClassnavapiWeb.Helpers.AssignmentHelper
  alias ClassnavapiWeb.Helpers.RepoHelper

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
        assign = Repo.get(Assignment, assignment.id)
        student_class = Repo.get_by(StudentClass, class_id: assign.class_id, student_id: params["student_id"])

        mod |> insert_mod(student_class)
      existing_mod == [] and assignment.from_mod == false -> 
        # The assignment is original, and should not have a mod.
        {:ok, existing_mod}
      existing_mod.is_private == true and mod.is_private == false ->
        # The assignment has a mod that needs to be published.
        assign = Repo.get(Assignment, assignment.id)
        student_class = Repo.get_by(StudentClass, class_id: assign.class_id, student_id: params["student_id"])

        mod |> publish_mod(student_class)
      true -> 
        # The assignment has a mod already, and needs no changes 
        assign = Repo.get(Assignment, assignment.id)
        student_class = Repo.get_by(StudentClass, class_id: assign.class_id, student_id: params["student_id"])

        Ecto.Multi.new
        |> Ecto.Multi.run(:backlog, &insert_backlogged_mods(existing_mod, student_class, &1))
        |> Ecto.Multi.run(:self_action, &process_self_action(existing_mod, student_class.id, &1))
    end
  end

  # Takes a Student Assignment for student a and applies the mods that created that assignment to student b.
  def insert_new_mod(%{assignment: %StudentAssignment{} = student_assignment}, params) do
    student_assignment = student_assignment |> Repo.preload(:student_class)
    student_class = Repo.get_by(StudentClass, class_id: student_assignment.student_class.class_id, student_id: params["student_id"], is_dropped: false)
    student_assignment
    |> find_mods()
    |> Enum.map(&process_existing_mod(&1, student_class, params))
    |> Enum.find({:ok, nil}, &RepoHelper.errors(&1))
  end

  def insert_update_mod(%{student_assignment: student_assignment}, %Ecto.Changeset{changes: changes}, params) do
    student_assignment = student_assignment |> Repo.preload(:assignment)
    status = changes |> Enum.map(&get_changes(&1, student_assignment, params))
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  def insert_delete_mod(%{student_assignment: student_assignment}, params) do
    student_class = Repo.get!(StudentClass, student_assignment.student_class_id)

    mod = %{
      data: %{},
      assignment_mod_type_id: @delete_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student_class.id,
      assignment_id: student_assignment.assignment_id
    }

    existing_mod = mod |> find_mod()
    cond do
      existing_mod == [] -> 
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, &process_self_action(existing_mod, student_class.id, &1))
        |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(existing_mod, student_class.id, &1))
        |> Repo.transaction()
    end
  end

  def apply_mod(%Mod{} = mod, %StudentClass{} = student_class) do
    case mod.assignment_mod_type_id do
      @delete_assignment_mod -> apply_delete_mod(mod, student_class)
      @new_assignment_mod -> apply_new_mod(mod, student_class)
      _ -> apply_change_mod(mod, student_class)
    end
  end

  def pending_mods_for_assignment(%StudentAssignment{} = student_assignment) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, m.id == act.assignment_modification_id and act.student_class_id == ^student_assignment.student_class_id)
    |> where([m], m.assignment_id == ^student_assignment.assignment_id)
    |> where([m, act], is_nil(act.is_accepted))
    |> Repo.all
  end

  def get_new_assignment_mods(%StudentClass{} = student_class) do
    from(mod in Mod)
    |> join(:inner, [mod], act in Action, mod.id == act.assignment_modification_id and act.student_class_id == ^student_class.id) 
    |> join(:inner, [mod, act], assign in Assignment, assign.id == mod.assignment_id)
    |> where([mod], mod.assignment_mod_type_id == ^@new_assignment_mod)
    |> where([mod, act], is_nil(act.is_accepted))
    |> select([mod, act, assign], assign)
    |> Repo.all()
  end

  defp insert_mod(mod, %StudentClass{} = student_class) do
    changeset = Mod.changeset(%Mod{}, mod)

    Ecto.Multi.new
    |> Ecto.Multi.insert(:mod, changeset)
    |> Ecto.Multi.run(:actions, &insert_public_mod_action(&1.mod, student_class))
    |> Ecto.Multi.run(:self_action, &process_self_action(&1.mod, student_class.id))
    |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(&1.mod, student_class.id))
    |> Repo.transaction()
  end

  defp publish_mod(mod, %StudentClass{} = student_class) do
    changeset = Mod.changeset(mod, %{is_private: false})
    
    Ecto.Multi.new
    |> Ecto.Multi.update(:mod, changeset)
    |> Ecto.Multi.run(:actions, &insert_public_mod_action(&1.mod, student_class))
    |> Ecto.Multi.run(:self_action, &process_self_action(&1.mod, student_class.id))
    |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(&1.mod, student_class.id))
    |> Repo.transaction()
  end

  defp process_existing_mod(mod, %StudentClass{} = student_class, params) do
    case mod.is_private == true and is_private(params["is_private"]) == false do
      true ->
        mod |> publish_mod(student_class)
      false -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, process_self_action(mod, student_class.id))
        |> Ecto.Multi.run(:dismissed, dismiss_prior_mods(mod, student_class.id))
        |> Repo.transaction()
    end
  end

  defp apply_delete_mod(%Mod{} = mod, %StudentClass{id: id}) do
    student_assignment = Repo.get_by!(StudentAssignment, assignment_id: mod.assignment_id, student_class_id: id)

    Ecto.Multi.new
    |> Ecto.Multi.delete(:student_assignment, student_assignment)
    |> Ecto.Multi.run(:mod_action, &insert_or_update_self_action(mod, &1.student_assignment.student_class_id))
  end

  defp apply_new_mod(%Mod{} = mod, %StudentClass{} = student_class) do
    student_assignment = Assignment
    |> Repo.get!(mod.assignment_id)
    |> AssignmentHelper.convert_assignment(student_class)

    Ecto.Multi.new
    |> Ecto.Multi.run(:student_assignment, &insert_student_assignment(student_assignment, &1))
    |> Ecto.Multi.run(:mod_action, &insert_or_update_self_action(mod, &1.student_assignment.student_class_id))
  end

  defp insert_student_assignment(student_assignment, _) do
    case Repo.get_by(StudentAssignment, assignment_id: student_assignment.assignment_id, student_class_id: student_assignment.student_class_id) do
      nil -> Repo.insert(student_assignment)
      assign -> {:ok, assign}
    end
  end

  defp apply_change_mod(%Mod{} = mod, %StudentClass{id: id}) do
    student_assignment = Repo.get_by!(StudentAssignment, assignment_id: mod.assignment_id, student_class_id: id)

    mod_change = mod
    |> get_data()

    Ecto.Multi.new
    |> Ecto.Multi.update(:student_assignment, Ecto.Changeset.change(student_assignment, mod_change))
    |> Ecto.Multi.run(:mod_action, &insert_or_update_self_action(mod, &1.student_assignment.student_class_id))
  end

  defp get_data(mod) do
    case mod.assignment_mod_type_id do
      @weight_assignment_mod -> %{weight_id: mod.data |> Map.get("weight_id")}
      @due_assignment_mod -> %{due: mod.data |> Map.get("due")}
      @name_assignment_mod -> %{name: mod.data |> Map.get("name")}
    end
  end

  #If there are no changes, this function will not be hit at all.
  defp get_changes(tuple, %{} = student_assignment, params) do
    case tuple do
      {:weight_id, weight_id} -> check_change(:weight, weight_id, student_assignment, params)
      {:due, due} -> check_change(:due, due, student_assignment, params)
      {:name, name} -> check_change(:name, name, student_assignment, params)
      _ -> {:ok, :no_mod}
    end
  end

  defp check_change(:weight, weight_id, %{assignment: %{weight_id: old_weight_id}} = student_assignment, params) do
    case old_weight_id == weight_id do
      false -> weight_id |> insert_weight_mod(student_assignment, params)
      true -> dismiss_mods(student_assignment, @weight_assignment_mod)
    end
  end

  defp check_change(:due, due, %{assignment: %{due: old_due}} = student_assignment, params) do
    case Date.compare(old_due, due) do
      :eq -> dismiss_mods(student_assignment, @due_assignment_mod)
      _ -> due |> insert_due_mod(student_assignment, params)
    end
  end

  defp check_change(:name, name, %{assignment: %{name: old_name}} = student_assignment, params) do
    case old_name == name do
      false -> name |> insert_name_mod(student_assignment, params)
      true -> dismiss_mods(student_assignment, @name_assignment_mod)
    end
  end

  defp insert_weight_mod(weight_id, %{} = student_assignment, params) do
    student_class = Repo.get!(StudentClass, student_assignment.student_class_id)

    mod = %{
      data: %{
        weight_id: weight_id
      },
      assignment_mod_type_id: @weight_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student_class.id,
      assignment_id: student_assignment.assignment.id
    }
    
    existing_mod = mod |> find_mod()
    cond do
      existing_mod == [] -> 
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, &process_self_action(existing_mod, student_class.id, &1))
        |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(existing_mod, student_class.id, &1))
        |> Repo.transaction()
    end
  end

  defp insert_due_mod(due, %{} = student_assignment, params) do
    student_class = Repo.get!(StudentClass, student_assignment.student_class_id)

    mod = %{
      data: %{
        due: due
      },
      assignment_mod_type_id: @due_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student_class.id,
      assignment_id: student_assignment.assignment.id
    }

    existing_mod = mod |> find_mod()
    cond do
      existing_mod == [] -> 
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, &process_self_action(existing_mod, student_class.id, &1))
        |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(existing_mod, student_class.id, &1))
        |> Repo.transaction()
    end
  end

  defp insert_name_mod(name, %{} = student_assignment, params) do
    student_class = Repo.get!(StudentClass, student_assignment.student_class_id)

    mod = %{
      data: %{
        name: name
      },
      assignment_mod_type_id: @name_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student_class.id,
      assignment_id: student_assignment.assignment.id
    }

    existing_mod = mod |> find_mod()
    cond do
      existing_mod == [] -> 
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, &process_self_action(existing_mod, student_class.id, &1))
        |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(existing_mod, student_class.id, &1))
        |> Repo.transaction()
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

  defp find_mods(%StudentAssignment{} = student_assignment) do
    from(mod in Mod)
    |> join(:inner, [mod], act in Action, mod.id == act.assignment_modification_id and act.student_class_id == ^student_assignment.student_class_id)
    |> where([mod], mod.assignment_id == ^student_assignment.assignment_id)
    |> Repo.all
  end

  defp insert_public_mod_action_query(%Mod{assignment_mod_type_id: @new_assignment_mod} = mod, %StudentClass{} = student_class) do
    from(sc in StudentClass)
    |> join(:left, [sc], act in Action, sc.id == act.student_class_id and act.assignment_modification_id == ^mod.id)
    |> where([sc], sc.class_id == ^student_class.class_id and sc.id != ^student_class.id)
    |> where([sc, act], is_nil(act.id))
    |> Repo.all()
  end

  defp insert_public_mod_action_query(%Mod{} = mod, student_class) do
    from(sc in StudentClass)
    |> join(:inner, [sc], assign in StudentAssignment, assign.student_class_id == sc.id and assign.assignment_id == ^mod.assignment_id)
    |> join(:left, [sc, assign], act in Action, sc.id == act.student_class_id and act.assignment_modification_id == ^mod.id)
    |> where([sc, assign, act], is_nil(act.id))
    |> where([sc], sc.id != ^student_class.id)
    |> Repo.all()
  end

  defp insert_public_mod_action(%Mod{is_private: false} = mod, %StudentClass{} = student_class) do
    status = mod
            |> insert_public_mod_action_query(student_class)
            |> Enum.map(&Repo.insert(%Action{assignment_modification_id: mod.id, student_class_id: &1.id, is_accepted: nil}))
    case status |> Enum.find({:ok, nil}, &RepoHelper.errors(&1)) do
      {:ok, nil} -> {:ok, status}
      {:error, val} -> {:error, val}
    end
  end

  defp insert_public_mod_action(%Mod{is_private: true}, %StudentClass{}), do: {:ok, nil}

  defp insert_or_update_self_action(%Mod{} = mod, student_class_id) do
    case process_self_action(mod, student_class_id) do
      {:ok, _new_action} -> dismiss_prior_mods(mod, student_class_id)
      {:error, error} -> {:error, error}
    end
  end

  defp process_self_action(%Mod{} = mod, student_class_id, _) do
    process_self_action(mod, student_class_id)
  end

  defp process_self_action(%Mod{id: mod_id}, student_class_id) do
    case Repo.get_by(Action, assignment_modification_id: mod_id, student_class_id: student_class_id) do
      nil -> Repo.insert(%Action{assignment_modification_id: mod_id, student_class_id: student_class_id, is_accepted: true})
      val -> val
              |> Ecto.Changeset.change(%{is_accepted: true})
              |> Repo.update()
    end
  end

  defp dismiss_prior_mods(%Mod{} = mod, student_class_id, _) do
    dismiss_prior_mods(mod, student_class_id)
  end

  defp dismiss_prior_mods(%Mod{} = mod, student_class_id) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, mod.id == action.assignment_modification_id and action.student_class_id == ^student_class_id)
    |> where([mod], mod.assignment_mod_type_id == ^mod.assignment_mod_type_id)
    |> where([mod], mod.assignment_id == ^mod.assignment_id)
    |> where([mod], mod.id != ^mod.id)
    |> where([mod, action], action.is_accepted == true)
    |> select([mod, action], action)
    |> Repo.all()
    |> dismiss_from_results()
  end

  defp dismiss_mods(%StudentAssignment{} = student_assignment, change_type) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, mod.id == action.assignment_modification_id and action.student_class_id == ^student_assignment.student_class_id)
    |> where([mod], mod.assignment_mod_type_id == ^change_type)
    |> where([mod], mod.assignment_id == ^student_assignment.assignment_id)
    |> where([mod, action], action.is_accepted == true)
    |> select([mod, action], action)
    |> Repo.all()
    |> dismiss_from_results()
  end

  defp dismiss_from_results(query) do
    case query do
      [] -> {:ok, nil}
      items -> 
        items = items |> Enum.map(&Repo.update!(Ecto.Changeset.change(&1, %{is_accepted: false})))
        {:ok, items}
    end
  end

  defp get_backlogged_mods(mod) do
    from(mod in Mod)
    |> where([mod], mod.assignment_id == ^mod.assignment_id)
    |> where([mod], mod.is_private == false)
    |> where([mod], mod.id != ^mod.id)
    |> Repo.all()
  end

  defp insert_backlogged_actions([], _student_class_id), do: {:ok, nil}
  defp insert_backlogged_actions(enumerable, student_class_id) do
    enumerable
    |> Enum.map(& &1 = Action.changeset(%Action{}, %{is_accepted: nil, assignment_modification_id: &1.id, student_class_id: student_class_id}))
    |> Enum.map(&Repo.insert!(&1))
    |> Enum.find({:ok, nil}, &RepoHelper.errors(&1))
  end

  defp insert_backlogged_mods(mod, %StudentClass{} = sc, _) do
    insert_backlogged_mods(mod, sc)
  end

  defp insert_backlogged_mods(mod, %StudentClass{id: id}) do
    mod
    |> get_backlogged_mods()
    |> insert_backlogged_actions(id)
  end

  defp is_private(nil), do: false
  defp is_private(value), do: value
end