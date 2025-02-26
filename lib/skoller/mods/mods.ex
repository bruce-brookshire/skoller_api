defmodule Skoller.Mods do
  @moduledoc """
  Context module for mods
  """

  alias Skoller.Mods.Mod
  alias Skoller.Mods.Action
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.Repo
  alias Skoller.Assignments.Assignment
  alias Skoller.StudentClasses
  alias Skoller.StudentAssignments
  alias Skoller.MapErrors
  alias Skoller.Assignments
  alias Skoller.EnrolledStudents
  alias Skoller.Mods.Assignments, as: ModAssignments
  alias Skoller.ModActions
  alias Skoller.Mods.Classes
  alias Skoller.AutoUpdates
  alias StructUtils

  import Ecto.Query

  @name_assignment_mod 100
  @weight_assignment_mod 200
  @due_assignment_mod 300
  @new_assignment_mod 400
  @delete_assignment_mod 500

  @doc """
  Gets a mod by id.

  Raises `Ecto.NoResultsError` if not found
  """
  def get_mod!(id) do
    Repo.get!(Mod, id)
  end

  @doc """
  This creates a new assignment mod from an assignment or a student assignment. It should
  be used when a new assignment or student assignment is created.

  ## Behavior for an assignment
   * This will create a mod if the assignment is not an original assignment and no prior mod exists.
   * If the assignment is original, it will do nothing
   * It will publish a mod (make it public) if there was a private mod, and a student decides to create a public one that is the same.
   * Will add back prior, missing actions from a previously deleted assignment if the assignment exists from others.

  ## Behavior for a student assignment
   * Finds all mods that were made to create the student assignment, and add them to the student.

  ## Returns
   * `{:ok, %{mod: Skoller.Mods.Mod, actions: [Skoller.Mods.Action], self_action: Skoller.Mods.Action, dismissed: Skoller.Mods.Action}}`
  where `mod` is the mod that is created, `actions` are the actions generated for the other students, `self_action` is the action created for the assignment creator, and
  `dismissed` are the actions that are dismissed as a result of creating the mod.
   * `{:ok, nil}` if the assignment is original and no mod is needed, or if a student assignment is used.
   * `{:ok, %{backlog: [Skoller.Mods.Action], self_action: Skoller.Mods.Action}}`
  """
  def insert_new_mod(%{assignment: %Assignment{from_mod: true} = assignment}, student_id, is_private) do
    mod = build_raw_mod(@new_assignment_mod, assignment, %{student_id: student_id, is_private: is_private})
    existing_mod = mod |> find_mod()
    student_class = StudentClasses.get_student_class_by_student_and_class(assignment.class_id, student_id)
    cond do
      is_nil(existing_mod) ->
        # The assignment is not an original assignment, and needs a mod.
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false ->
        # The assignment has a mod that needs to be published.
        mod |> publish_mod(student_class)
      true -> 
        # The assignment has a mod already, and needs no changes 
        existing_mod |> add_mods_and_actions_for_existing_assignment(student_class)
    end
  end
  # The assignment is original, and should not have a mod.
  def insert_new_mod(%{assignment: %Assignment{from_mod: false}}, _student_id, _is_private), do: {:ok, nil}
  # Takes a Student Assignment for student a and applies the mods that created that assignment to student b.
  def insert_new_mod(%{assignment: %StudentAssignment{} = student_assignment}, student_id, is_private) do
    student_assignment = student_assignment |> Repo.preload(:student_class)
    student_class = EnrolledStudents.get_enrolled_class_by_ids!(student_assignment.student_class.class_id, student_id)
    student_assignment
    |> find_accepted_mods_for_student_assignment()
    |> Enum.map(&process_existing_mod(&1, student_class, is_private))
    |> Enum.find({:ok, nil}, &MapErrors.check_tuple(&1))
  end

  @doc """
  Compares a student assignment with a changeset's changes, and adds mods when there are differences.

  ## Mod Types
   * Due date changes on the `due` field
   * Name changes on the `name` field
   * Weight changes on the `weight_id` field.

  ## Behavior
   * If a change is reverted back to the original assignment's value for a given type, all accepted mods of that type will be dismissed.

  ## Returns
  `{:ok, [t]}` where `t` is any item from the list below.
   * `{:ok, :no_mod}` when there are no changes.
   * `{:ok, %{mod: Skoller.Mods.Mod, actions: [Skoller.Mods.Action], self_action: Skoller.Mods.Action, dismissed: Skoller.Mods.Action}}`
  where `mod` is the mod that is created, `actions` are the actions generated for the other students, `self_action` is the action created for the assignment creator, and
  `dismissed` are the actions that are dismissed as a result of creating the mod.
   * `{:ok, [Skoller.Mods.Action]}` when there are actions that are dismissed due to reverting back to no changes.
   * `{:ok, nil}`
   * `{:ok, %{self_action: Skoller.Mods.Action, dismissed: Skoller.Mods.Action}}`
  """
  def insert_update_mod(%{student_assignment: student_assignment}, %Ecto.Changeset{changes: changes}, is_private) do
    student_assignment = student_assignment |> Repo.preload(:assignment)
    status = changes |> Enum.map(&check_change(&1, student_assignment, is_private))
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  @doc """
  Inserts a mod when someone deletes an assignment.

  ## Returns
   * `{:ok, %{mod: Skoller.Mods.Mod, actions: [Skoller.Mods.Action], self_action: Skoller.Mods.Action, dismissed: Skoller.Mods.Action}}`
  where `mod` is the mod that is created, `actions` are the actions generated for the other students, `self_action` is the action created for the assignment creator, and
  `dismissed` are the actions that are dismissed as a result of creating the mod.
   * `{:ok, %{self_action: Skoller.Mods.Action, dismissed: Skoller.Mods.Action}}`
  """
  def insert_delete_mod(%{student_assignment: student_assignment}, is_private) do
    student_class = StudentClasses.get_student_class_by_id!(student_assignment.student_class_id)
    mod = build_raw_mod(@delete_assignment_mod, student_assignment, %{is_private: is_private, student_id: student_class.student_id})
    existing_mod = mod |> find_mod()
    cond do
      is_nil(existing_mod) -> 
        mod |> insert_mod(student_class, student_assignment)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class, student_assignment)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, fn (_, changes) -> accept_action(existing_mod.id, student_class.id, changes, [manual: true]) end)
        |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_mods(student_assignment, mod.assignment_mod_type_id, changes) end)
        |> Repo.transaction()
    end
  end

  @doc """
  Applies a mod to a student assignment.

  ## Behavior
  This will either create, delete, or change a student assignment.

  ## Returns
  Completed Repo Transaction with the following keys depending on mod type.
   * New mod: `[:student_assignment, :backfill_mods, :self_action, :dismissed]`
   * Delete mod: `[:student_assignment, :self_action, :dismissed]`
   * Change mod: `[:student_assignment, :backfill_mods, :self_action, :dismissed]`
  """
  def apply_mod(mod, student_class, opts \\ [manual: true])
  def apply_mod(%Mod{assignment_mod_type_id: @delete_assignment_mod} = mod, student_class, opts) do
    student_assignment = StudentAssignments.get_assignment_by_ids(mod.assignment_id, student_class.id)
    apply_delete_mod(mod, student_assignment, opts)
  end
  def apply_mod(%Mod{assignment_mod_type_id: @new_assignment_mod} = mod, student_class, opts) do
    apply_new_mod(mod, student_class, opts)
  end
  def apply_mod(%Mod{} = mod, student_class, opts) do
    apply_change_mod(mod, student_class, opts)
  end

  @doc """
  Updates a mod.

  ## Returns
  `{:ok, %Skoller.Mods.Mod{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def update_mod(mod_old, params) do
    mod_old
    |> Ecto.Changeset.change(params)
    |> Repo.update()
  end

  @doc """
  Accepts a mod for the given student.

  ## Returns
  `{:ok, student_assignment}` or `{:error, changeset}`
  """
  def manual_accept_mod_for_student(mod_id, student_id) do
    mod = get_mod!(mod_id)
    class = Classes.get_class_from_mod_id(mod.id)

    #Verifies that a student has permissions/is in the class/has the mod.
    student_class = StudentClasses.get_active_student_class_by_ids!(class.id, student_id)

    result = apply_mod(mod, student_class)
    |> check_auto_updates(mod)

    case result do
      {:ok, %{student_assignment: student_assignment}} ->
        {:ok, student_assignment}
      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Rejects a mod for the given student.

  ## Returns
  `{:ok, action}` or `{:error, changeset}`
  """
  def manual_reject_mod_for_student(mod_id, student_id) do
    mod = get_mod!(mod_id)
    class = Classes.get_class_from_mod_id(mod.id)

    #Verifies that a student has permissions/is in the class/has the mod.
    student_class = StudentClasses.get_active_student_class_by_ids!(class.id, student_id)

    ModActions.get_action_by_mod_and_student!(mod.id, student_class.id)
    |> ModActions.manual_dismiss_action()
  end

  defp check_auto_updates({:ok, _result} = result, mod) do
    Task.start(AutoUpdates, :process_auto_update, [mod, [notification: true]])
    result
  end
  defp check_auto_updates(result, _mod), do: result

  defp build_raw_mod(assignment_mod_type_id, map, params)
  defp build_raw_mod(@new_assignment_mod, assignment, params) do
    %{
      data: %{
        assignment: assignment |> StructUtils.to_storeable_map()
      },
      assignment_mod_type_id: @new_assignment_mod,
      is_private: is_private(params.is_private),
      student_id: params.student_id,
      assignment_id: assignment.id
    }
  end
  defp build_raw_mod(@delete_assignment_mod, assignment, params) do
    %{
      data: %{},
      assignment_mod_type_id: @delete_assignment_mod,
      is_private: is_private(params.is_private),
      student_id: params.student_id,
      assignment_id: assignment.assignment_id
    }
  end
  defp build_raw_mod(@weight_assignment_mod, student_assignment, params) do
    %{
      data: %{
        weight_id: params.weight_id
      },
      assignment_mod_type_id: @weight_assignment_mod,
      is_private: is_private(params.is_private),
      student_id: params.student_id,
      assignment_id: student_assignment.assignment.id
    }
  end
  defp build_raw_mod(@due_assignment_mod, student_assignment, params) do
    %{
      data: %{
        due: params.due
      },
      assignment_mod_type_id: @due_assignment_mod,
      is_private: params.is_private,
      student_id: params.student_id,
      assignment_id: student_assignment.assignment.id
    }
  end
  defp build_raw_mod(@name_assignment_mod, student_assignment, params) do
    %{
      data: %{
        name: params.name
      },
      assignment_mod_type_id: @name_assignment_mod,
      is_private: is_private(params.is_private),
      student_id: params.student_id,
      assignment_id: student_assignment.assignment.id
    }
  end

  defp apply_delete_mod(_mod, nil, _atom), do: Ecto.Multi.new
  defp apply_delete_mod(mod, student_assignment, opts) do
    Ecto.Multi.new
    |> Ecto.Multi.delete(:student_assignment, student_assignment)
    |> Ecto.Multi.run(:self_action, fn (_, changes) -> ModActions.accept_action(mod.id, changes.student_assignment.student_class_id, opts) end)
    |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_mods(student_assignment, mod.assignment_mod_type_id, changes) end)
    |> Repo.transaction()
  end

  defp apply_new_mod(%Mod{} = mod, %StudentClass{} = student_class, opts) do
    student_assignment = Assignments.get_assignment_by_id!(mod.assignment_id)
    |> StudentAssignments.convert_assignment(student_class)

    Ecto.Multi.new
    |> Ecto.Multi.run(:student_assignment, fn (_, changes) -> insert_student_assignment(student_assignment, changes) end)
    |> Ecto.Multi.run(:backfill_mods, fn (_, changes) -> backfill_mods(changes.student_assignment) end)
    |> Ecto.Multi.run(:self_action, fn (_, changes) -> ModActions.accept_action(mod.id, changes.student_assignment.student_class_id, opts) end)
    |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_mods(changes.student_assignment, mod.assignment_mod_type_id, nil) end)
    |> Repo.transaction()
  end

  defp apply_change_mod(%Mod{} = mod, %StudentClass{id: id}, opts) do
    student_assignment = StudentAssignments.get_assignment_by_ids!(mod.assignment_id, id)
    mod_change = mod |> get_data()

    Ecto.Multi.new
    |> Ecto.Multi.update(:student_assignment, Ecto.Changeset.change(student_assignment, mod_change))
    |> Ecto.Multi.run(:self_action, fn (_, changes) -> ModActions.accept_action(mod.id, changes.student_assignment.student_class_id, opts) end)
    |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_prior_mods(mod, changes.student_assignment.student_class_id, nil) end)
    |> Repo.transaction()
  end

  # Backfills mods for a given student assignment.
  defp backfill_mods(student_assignment) do
    missing_mods = from(mod in Mod)
    |> join(:left, [mod], act in Action, on: act.assignment_modification_id == mod.id and act.student_class_id == ^student_assignment.student_class_id)
    |> where([mod, act], mod.assignment_id == ^student_assignment.assignment_id)
    |> where([mod, act], is_nil(act.id))
    |> where([mod], mod.is_private == false)
    |> Repo.all()

    status = missing_mods |> Enum.map(&Repo.insert(%Action{is_accepted: nil, assignment_modification_id: &1.id, student_class_id: student_assignment.student_class_id}))
    
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  #compare new change with original assignment. If original, dismiss mods. Otherwise, create mod.
  defp check_change({:weight_id, weight_id}, %{assignment: %{weight_id: old_weight_id}} = student_assignment, is_private) do
    case old_weight_id == weight_id do
      false -> weight_id |> insert_weight_mod(student_assignment, is_private)
      true -> dismiss_mods(student_assignment, @weight_assignment_mod, nil)
    end
  end
  defp check_change({:due, due}, %{assignment: %{due: old_due}} = student_assignment, is_private) do
    case compare_dates(old_due, due) do
      :eq -> dismiss_mods(student_assignment, @due_assignment_mod, nil)
      _ -> due |> insert_due_mod(student_assignment, is_private)
    end
  end
  defp check_change({:name, name}, %{assignment: %{name: old_name}} = student_assignment, is_private) do
    case old_name == name do
      false -> name |> insert_name_mod(student_assignment, is_private)
      true -> dismiss_mods(student_assignment, @name_assignment_mod, nil)
    end
  end
  defp check_change(_tuple, _student_assignment, _params), do: {:ok, :no_mod}

  defp insert_weight_mod(weight_id, %{} = student_assignment, is_private) do
    student_class = StudentClasses.get_student_class_by_id!(student_assignment.student_class_id)
    mod = build_raw_mod(@weight_assignment_mod, student_assignment, %{is_private: is_private, student_id: student_class.student_id, weight_id: weight_id})
    
    existing_mod = mod |> find_mod()
    cond do
      is_nil(existing_mod) -> 
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, fn (_, changes) -> accept_action(existing_mod.id, student_class.id, changes, [manual: true]) end)
        |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_prior_mods(existing_mod, student_class.id, changes) end)
        |> Repo.transaction()
    end
  end

  defp insert_due_mod(due, %{} = student_assignment, is_private) do
    student_class = StudentClasses.get_student_class_by_id!(student_assignment.student_class_id)
    now = DateTime.utc_now()
    #Due dates being set to the past are automatically private.
    is_private = case DateTime.compare(now, due) do
      :gt -> true
      _ -> is_private(is_private)
    end
    mod = build_raw_mod(@due_assignment_mod, student_assignment, %{due: due, student_id: student_class.student_id, is_private: is_private})

    existing_mod = mod |> find_mod()
    cond do
      is_nil(existing_mod) -> 
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, fn (_, changes) -> accept_action(existing_mod.id, student_class.id, changes, [manual: true]) end)
        |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_prior_mods(existing_mod, student_class.id, changes) end)
        |> Repo.transaction()
    end
  end

  defp insert_name_mod(name, %{} = student_assignment, is_private) do
    student_class = StudentClasses.get_student_class_by_id!(student_assignment.student_class_id)
    mod = build_raw_mod(@name_assignment_mod, student_assignment, %{name: name, is_private: is_private, student_id: student_class})
    existing_mod = mod |> find_mod()
    cond do
      is_nil(existing_mod) -> 
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, fn (_, changes) -> accept_action(existing_mod.id, student_class.id, changes, [manual: true]) end)
        |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_prior_mods(existing_mod, student_class.id, changes) end)
        |> Repo.transaction()
    end
  end

  defp insert_student_assignment(student_assignment, _) do
    case StudentAssignments.get_assignment_by_ids(student_assignment.assignment_id, student_assignment.student_class_id) do
      nil -> Repo.insert(student_assignment)
      assign -> {:ok, assign}
    end
  end

  defp dismiss_mods(%StudentAssignment{} = student_assignment, @new_assignment_mod, _) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, on: mod.id == action.assignment_modification_id and action.student_class_id == ^student_assignment.student_class_id)
    |> where([mod], mod.assignment_mod_type_id == @delete_assignment_mod)
    |> where([mod], mod.assignment_id == ^student_assignment.assignment_id)
    |> select([mod, action], action)
    |> Repo.all()
    |> ModActions.dismiss_actions()
  end
  defp dismiss_mods(%StudentAssignment{} = student_assignment, @delete_assignment_mod, _) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, on: mod.id == action.assignment_modification_id and action.student_class_id == ^student_assignment.student_class_id)
    |> where([mod], mod.assignment_mod_type_id != @delete_assignment_mod)
    |> where([mod], mod.assignment_id == ^student_assignment.assignment_id)
    |> select([mod, action], action)
    |> Repo.all()
    |> ModActions.dismiss_actions()
  end
  defp dismiss_mods(%StudentAssignment{} = student_assignment, change_type, _) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, on: mod.id == action.assignment_modification_id and action.student_class_id == ^student_assignment.student_class_id)
    |> where([mod], mod.assignment_mod_type_id == ^change_type)
    |> where([mod], mod.assignment_id == ^student_assignment.assignment_id)
    |> select([mod, action], action)
    |> Repo.all()
    |> ModActions.dismiss_actions()
  end

  defp find_accepted_mods_for_student_assignment(%StudentAssignment{} = student_assignment) do
    from(mod in Mod)
    |> join(:inner, [mod], act in Action, on: mod.id == act.assignment_modification_id and act.student_class_id == ^student_assignment.student_class_id and act.is_accepted == true)
    |> where([mod], mod.assignment_id == ^student_assignment.assignment_id)
    |> Repo.all
  end

  # TODO: Fix when data is fixed to be Repo.one()
  defp find_mod(%{assignment_mod_type_id: @new_assignment_mod} = mod) do
    from(mod in Mod)
    |> where([mod], mod.assignment_id == ^mod.assignment_id)
    |> Repo.all()
    |> List.first()
  end
  defp find_mod(mod) do
    from(mod in Mod)
    |> where([mod], mod.assignment_id == ^mod.assignment_id and mod.data == ^mod.data)
    |> Repo.one()
  end

  defp insert_mod(mod, %StudentClass{} = student_class) do
    changeset = Mod.changeset(%Mod{}, mod)
    Ecto.Multi.new
    |> Ecto.Multi.insert(:mod, changeset)
    |> Ecto.Multi.run(:actions, fn (_, changes) -> ModActions.insert_mod_actions_for_class(changes.mod, student_class) end)
    |> Ecto.Multi.run(:self_action, fn (_, changes) -> ModActions.accept_action(changes.mod.id, student_class.id, [manual: true]) end)
    |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_prior_mods(changes.mod, student_class.id, nil) end)
    |> Repo.transaction()
  end

  defp publish_mod(mod, %StudentClass{} = student_class) do
    changeset = Mod.changeset(mod, %{is_private: false})
    
    Ecto.Multi.new
    |> Ecto.Multi.update(:mod, changeset)
    |> Ecto.Multi.run(:actions, fn (_, changes) -> ModActions.insert_mod_actions_for_class(changes.mod, student_class) end)
    |> Ecto.Multi.run(:self_action, fn (_, changes) -> ModActions.accept_action(changes.mod.id, student_class.id, [manual: true]) end)
    |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_prior_mods(changes.mod, student_class.id, nil) end)
    |> Repo.transaction()
  end

  defp insert_mod(%{assignment_mod_type_id: @delete_assignment_mod} = mod, %StudentClass{} = student_class, student_assignment) do
    changeset = Mod.changeset(%Mod{}, mod)

    Ecto.Multi.new
    |> Ecto.Multi.insert(:mod, changeset)
    |> Ecto.Multi.run(:actions, fn (_, changes) -> ModActions.insert_mod_actions_for_class(changes.mod, student_class) end)
    |> Ecto.Multi.run(:self_action, fn (_, changes) -> ModActions.accept_action(changes.mod.id, student_class.id, [manual: true]) end)
    |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_mods(student_assignment, mod.assignment_mod_type_id, changes) end)
    |> Repo.transaction()
  end

  defp publish_mod(%{assignment_mod_type_id: @delete_assignment_mod} = mod, %StudentClass{} = student_class, student_assignment) do
    changeset = Mod.changeset(mod, %{is_private: false})
    
    Ecto.Multi.new
    |> Ecto.Multi.update(:mod, changeset)
    |> Ecto.Multi.run(:actions, fn (_, changes) -> ModActions.insert_mod_actions_for_class(changes.mod, student_class) end)
    |> Ecto.Multi.run(:self_action, fn (_, changes) -> ModActions.accept_action(changes.mod.id, student_class.id, [manual: true]) end)
    |> Ecto.Multi.run(:dismissed, fn (_, changes) -> dismiss_mods(student_assignment, mod.assignment_mod_type_id, changes) end)
    |> Repo.transaction()
  end

  defp process_existing_mod(%{is_private: true} = mod, %StudentClass{} = student_class, false) do
    mod |> publish_mod(student_class)
  end
  defp process_existing_mod(mod, %StudentClass{} = student_class, _is_private) do
    Ecto.Multi.new
    |> Ecto.Multi.run(:self_action, fn (_,_) -> ModActions.accept_action(mod.id, student_class.id, [manual: true]) end)
    |> Ecto.Multi.run(:dismissed, fn (_,_) -> dismiss_prior_mods(mod, student_class.id, nil) end)
    |> Repo.transaction()
  end
  
  defp add_mods_and_actions_for_existing_assignment(existing_mod, student_class) do
    Ecto.Multi.new
    |> Ecto.Multi.run(:backlog, fn (_, changes) -> insert_mods_for_existing_assignment(existing_mod, student_class.id, changes) end)
    |> Ecto.Multi.run(:self_action, fn (_, changes) -> accept_action(existing_mod.id, student_class.id, changes, [manual: true]) end)
    |> Repo.transaction()
  end

  defp insert_mods_for_existing_assignment(mod, student_class_id, _) do
    mod
    |> ModAssignments.get_other_mods_for_assignment_by_mod()
    |> ModActions.insert_mod_action_for_mods(student_class_id)
  end

  defp accept_action(mod_id, student_class_id, _, opts) do
    ModActions.accept_action(mod_id, student_class_id, opts)
  end

  defp dismiss_prior_mods(%Mod{} = mod, student_class_id, _) do
    mod
    |> get_other_same_type_mods(student_class_id)
    |> ModActions.dismiss_actions()
  end

  defp get_other_same_type_mods(mod, student_class_id) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, on: mod.id == action.assignment_modification_id and action.student_class_id == ^student_class_id)
    |> where([mod], mod.assignment_mod_type_id == ^mod.assignment_mod_type_id)
    |> where([mod], mod.assignment_id == ^mod.assignment_id)
    |> where([mod], mod.id != ^mod.id)
    |> select([mod, action], action)
    |> Repo.all()
  end

  defp get_data(%{assignment_mod_type_id: @weight_assignment_mod, data: data}) do
    %{weight_id: data |> Map.get("weight_id")}
  end
  defp get_data(%{assignment_mod_type_id: @due_assignment_mod, data: data}) do
    %{due: data |> Map.get("due") |> get_due_date()}
  end
  defp get_data(%{assignment_mod_type_id: @name_assignment_mod, data: data}) do
    %{name: data |> Map.get("name")}
  end

  defp get_due_date(nil), do: nil
  defp get_due_date(date) do 
    {:ok, iso_date, _} = date |> DateTime.from_iso8601()
    iso_date
  end

  defp is_private(nil), do: false
  defp is_private(value), do: value

  defp compare_dates(nil, nil), do: :eq
  defp compare_dates(nil, _due), do: :neq
  defp compare_dates(_old_due, nil), do: :neq
  defp compare_dates(old_due, due) do
    DateTime.compare(old_due, due)
  end
end