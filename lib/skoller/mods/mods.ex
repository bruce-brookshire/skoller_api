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

  import Ecto.Query

  @name_assignment_mod 100
  @weight_assignment_mod 200
  @due_assignment_mod 300
  @new_assignment_mod 400
  @delete_assignment_mod 500

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
      is_nil(existing_mod) and assignment.from_mod == true ->
        # The assignment is not an original assignment, and needs a mod.
        mod |> insert_mod(StudentClasses.get_student_class_by_student_and_class(assignment.class_id, params["student_id"]))
      is_nil(existing_mod) and assignment.from_mod == false -> 
        # The assignment is original, and should not have a mod.
        {:ok, existing_mod}
      existing_mod.is_private == true and mod.is_private == false ->
        # The assignment has a mod that needs to be published.
        mod |> publish_mod(StudentClasses.get_student_class_by_student_and_class(assignment.class_id, params["student_id"]))
      true -> 
        # The assignment has a mod already, and needs no changes 
        student_class = StudentClasses.get_student_class_by_student_and_class(assignment.class_id, params["student_id"])
        Ecto.Multi.new
        |> Ecto.Multi.run(:backlog, &insert_backlogged_mods(existing_mod, student_class, &1))
        |> Ecto.Multi.run(:self_action, &process_self_action(existing_mod, student_class.id, &1, :manual))
        |> Repo.transaction()
    end
  end
  # Takes a Student Assignment for student a and applies the mods that created that assignment to student b.
  def insert_new_mod(%{assignment: %StudentAssignment{} = student_assignment}, params) do
    student_assignment = student_assignment |> Repo.preload(:student_class)
    student_class = EnrolledStudents.get_enrolled_class_by_ids!(student_assignment.student_class.class_id, params["student_id"])
    student_assignment
    |> find_accepted_mods_for_student_assignment()
    |> Enum.map(&process_existing_mod(&1, student_class, params))
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
  def insert_update_mod(%{student_assignment: student_assignment}, %Ecto.Changeset{changes: changes}, params) do
    student_assignment = student_assignment |> Repo.preload(:assignment)
    status = changes |> Enum.map(&check_change(&1, student_assignment, params))
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
  def insert_delete_mod(%{student_assignment: student_assignment}, params) do
    student_class = StudentClasses.get_student_class_by_id!(student_assignment.student_class_id)

    mod = %{
      data: %{},
      assignment_mod_type_id: @delete_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student_class.student_id,
      assignment_id: student_assignment.assignment_id
    }

    existing_mod = mod |> find_mod()
    cond do
      is_nil(existing_mod) -> 
        mod |> insert_mod(student_class, student_assignment)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class, student_assignment)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, &process_self_action(existing_mod, student_class.id, &1, :manual))
        |> Ecto.Multi.run(:dismissed, &dismiss_mods(student_assignment, mod.assignment_mod_type_id, &1))
        |> Repo.transaction()
    end
  end

  @doc """
  Applies all actions that are currently nil in `actions`.

  See `apply_mod/3`.

  ## Returns
  `{:ok, [t]}` where `t` is the result of `apply_mod/3`
  """
  def apply_mods(actions, _) do
    nil_actions = actions |> Enum.filter(&is_nil(&1.is_accepted))

    status = nil_actions |> Enum.map(&apply_action_mods(&1))
    
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  @doc """
  Applies a mod to a student assignment.

  ## Behavior
  This will either create, delete, or change a student assignment.

  ## Returns
  `Ecto.Multi` with the following keys depending on mod type.
   * New mod: `[:student_assignment, :backfill_mods, :self_action, :dismissed]`
   * Delete mod: `[:student_assignment, :self_action, :dismissed]`
   * Change mod: `[:student_assignment, :backfill_mods, :self_action, :dismissed]`
  """
  def apply_mod(%Mod{} = mod, %StudentClass{} = student_class, atom \\ :manual) do
    case mod.assignment_mod_type_id do
      @delete_assignment_mod -> apply_delete_mod(mod, student_class, atom)
      @new_assignment_mod -> apply_new_mod(mod, student_class, atom)
      _ -> apply_change_mod(mod, student_class, atom)
    end
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
  Gets unanswered mods for a student assignment.

  An unanswered mod is when `is_accepted` is `nil`

  ## Returns
  `[Skoller.Mods.Mod]` or `[]`
  """
  def pending_mods_for_student_assignment(%{student_class_id: student_class_id, assignment_id: assignment_id}) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, m.id == act.assignment_modification_id and act.student_class_id == ^student_class_id)
    |> where([m], m.assignment_id == ^assignment_id)
    |> where([m, act], is_nil(act.is_accepted))
    |> Repo.all
  end

  @doc """
  Gets new assignment mods for a student that are unanswered.

  An unanswered mod is when `is_accepted` is `nil`

  ## Returns
  `[Skoller.Assignments.Assignment]` or `[]`
  """
  def get_new_assignment_mods(%StudentClass{} = student_class) do
    from(mod in Mod)
    |> join(:inner, [mod], act in Action, mod.id == act.assignment_modification_id and act.student_class_id == ^student_class.id) 
    |> join(:inner, [mod, act], assign in Assignment, assign.id == mod.assignment_id)
    |> where([mod], mod.assignment_mod_type_id == ^@new_assignment_mod)
    |> where([mod, act], is_nil(act.is_accepted))
    |> Repo.all()
  end

  defp apply_action_mods(action) do
    student_class = StudentClasses.get_student_class_by_id!(action.student_class_id)
    mod = Repo.get!(Mod, action.assignment_modification_id)
    Repo.transaction(apply_mod(mod, student_class, :auto))
  end

  defp apply_delete_mod(%Mod{} = mod, %StudentClass{id: id}, atom) do
    case StudentAssignments.get_assignment_by_ids(mod.assignment_id, id) do
      nil ->
        Ecto.Multi.new
      student_assignment -> 
        Ecto.Multi.new
        |> Ecto.Multi.delete(:student_assignment, student_assignment)
        |> Ecto.Multi.run(:self_action, &process_self_action(mod, &1.student_assignment.student_class_id, atom))
        |> Ecto.Multi.run(:dismissed, &dismiss_mods(student_assignment, mod.assignment_mod_type_id, &1))
    end
  end

  defp apply_new_mod(%Mod{} = mod, %StudentClass{} = student_class, atom) do
    student_assignment = Assignments.get_assignment_by_id!(mod.assignment_id)
    |> StudentAssignments.convert_assignment(student_class)

    Ecto.Multi.new
    |> Ecto.Multi.run(:student_assignment, &insert_student_assignment(student_assignment, &1))
    |> Ecto.Multi.run(:backfill_mods, &backfill_mods(&1.student_assignment))
    |> Ecto.Multi.run(:self_action, &process_self_action(mod, &1.student_assignment.student_class_id, atom))
    |> Ecto.Multi.run(:dismissed, &dismiss_mods(&1.student_assignment, @delete_assignment_mod))
  end

  defp apply_change_mod(%Mod{} = mod, %StudentClass{id: id}, atom) do
    student_assignment = StudentAssignments.get_assignment_by_ids!(mod.assignment_id, id)

    mod_change = mod |> get_data()

    Ecto.Multi.new
    |> Ecto.Multi.update(:student_assignment, Ecto.Changeset.change(student_assignment, mod_change))
    |> Ecto.Multi.run(:self_action, &process_self_action(mod, &1.student_assignment.student_class_id, atom))
    |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(mod, &1.student_assignment.student_class_id))
  end

  # Backfills mods for a given student assignment.
  defp backfill_mods(student_assignment) do
    missing_mods = from(mod in Mod)
    |> join(:left, [mod], act in Action, act.assignment_modification_id == mod.id and act.student_class_id == ^student_assignment.student_class_id)
    |> where([mod, act], mod.assignment_id == ^student_assignment.assignment_id)
    |> where([mod, act], is_nil(act.id))
    |> where([mod], mod.is_private == false)
    |> Repo.all()

    status = missing_mods |> Enum.map(&Repo.insert(%Action{is_accepted: nil, assignment_modification_id: &1.id, student_class_id: student_assignment.student_class_id}))
    
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  #compare new change with original assignment. If original, dismiss mods. Otherwise, create mod.
  defp check_change({:weight_id, weight_id}, %{assignment: %{weight_id: old_weight_id}} = student_assignment, params) do
    case old_weight_id == weight_id do
      false -> weight_id |> insert_weight_mod(student_assignment, params)
      true -> dismiss_mods(student_assignment, @weight_assignment_mod)
    end
  end
  defp check_change({:due, due}, %{assignment: %{due: old_due}} = student_assignment, params) do
    case compare_dates(old_due, due) do
      :eq -> dismiss_mods(student_assignment, @due_assignment_mod)
      _ -> due |> insert_due_mod(student_assignment, params)
    end
  end
  defp check_change({:name, name}, %{assignment: %{name: old_name}} = student_assignment, params) do
    case old_name == name do
      false -> name |> insert_name_mod(student_assignment, params)
      true -> dismiss_mods(student_assignment, @name_assignment_mod)
    end
  end
  defp check_change(_tuple, _student_assignment, _params), do: {:ok, :no_mod}

  defp insert_weight_mod(weight_id, %{} = student_assignment, params) do
    student_class = StudentClasses.get_student_class_by_id!(student_assignment.student_class_id)

    mod = %{
      data: %{
        weight_id: weight_id
      },
      assignment_mod_type_id: @weight_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student_class.student_id,
      assignment_id: student_assignment.assignment.id
    }
    
    existing_mod = mod |> find_mod()
    cond do
      is_nil(existing_mod) -> 
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, &process_self_action(existing_mod, student_class.id, &1, :manual))
        |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(existing_mod, student_class.id, &1))
        |> Repo.transaction()
    end
  end

  defp insert_due_mod(due, %{} = student_assignment, params) do
    student_class = StudentClasses.get_student_class_by_id!(student_assignment.student_class_id)

    now = DateTime.utc_now()

    #Due dates being set to the past are automatically private.
    is_private = case DateTime.compare(now, due) do
      :gt -> true
      _ -> is_private(params["is_private"])
    end

    mod = %{
      data: %{
        due: due
      },
      assignment_mod_type_id: @due_assignment_mod,
      is_private: is_private,
      student_id: student_class.student_id,
      assignment_id: student_assignment.assignment.id
    }

    existing_mod = mod |> find_mod()
    cond do
      is_nil(existing_mod) -> 
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, &process_self_action(existing_mod, student_class.id, &1, :manual))
        |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(existing_mod, student_class.id, &1))
        |> Repo.transaction()
    end
  end

  defp insert_name_mod(name, %{} = student_assignment, params) do
    student_class = StudentClasses.get_student_class_by_id!(student_assignment.student_class_id)

    mod = %{
      data: %{
        name: name
      },
      assignment_mod_type_id: @name_assignment_mod,
      is_private: is_private(params["is_private"]),
      student_id: student_class.student_id,
      assignment_id: student_assignment.assignment.id
    }

    existing_mod = mod |> find_mod()
    cond do
      is_nil(existing_mod) -> 
        mod |> insert_mod(student_class)
      existing_mod.is_private == true and mod.is_private == false -> 
        mod |> publish_mod(student_class)
      true -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, &process_self_action(existing_mod, student_class.id, &1, :manual))
        |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(existing_mod, student_class.id, &1))
        |> Repo.transaction()
    end
  end

  defp insert_student_assignment(student_assignment, _) do
    case StudentAssignments.get_assignment_by_ids(student_assignment.assignment_id, student_assignment.student_class_id) do
      nil -> Repo.insert(student_assignment)
      assign -> {:ok, assign}
    end
  end

  defp dismiss_mods(%StudentAssignment{} = student_assignment, change_type) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, mod.id == action.assignment_modification_id and action.student_class_id == ^student_assignment.student_class_id)
    |> where([mod], mod.assignment_mod_type_id == ^change_type)
    |> where([mod], mod.assignment_id == ^student_assignment.assignment_id)
    |> select([mod, action], action)
    |> Repo.all()
    |> dismiss_from_results()
  end

  defp dismiss_mods(%StudentAssignment{} = student_assignment, @delete_assignment_mod, _) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, mod.id == action.assignment_modification_id and action.student_class_id == ^student_assignment.student_class_id)
    |> where([mod], mod.assignment_mod_type_id != @delete_assignment_mod)
    |> where([mod], mod.assignment_id == ^student_assignment.assignment_id)
    |> select([mod, action], action)
    |> Repo.all()
    |> dismiss_from_results()
  end

  defp find_accepted_mods_for_student_assignment(%StudentAssignment{} = student_assignment) do
    from(mod in Mod)
    |> join(:inner, [mod], act in Action, mod.id == act.assignment_modification_id and act.student_class_id == ^student_assignment.student_class_id and act.is_accepted == true)
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
    |> Ecto.Multi.run(:actions, &insert_public_mod_action(&1.mod, student_class))
    |> Ecto.Multi.run(:self_action, &process_self_action(&1.mod, student_class.id, :manual))
    |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(&1.mod, student_class.id))
    |> Repo.transaction()
  end

  defp publish_mod(mod, %StudentClass{} = student_class) do
    changeset = Mod.changeset(mod, %{is_private: false})
    
    Ecto.Multi.new
    |> Ecto.Multi.update(:mod, changeset)
    |> Ecto.Multi.run(:actions, &insert_public_mod_action(&1.mod, student_class))
    |> Ecto.Multi.run(:self_action, &process_self_action(&1.mod, student_class.id, :manual))
    |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(&1.mod, student_class.id))
    |> Repo.transaction()
  end

  defp insert_mod(%{assignment_mod_type_id: @delete_assignment_mod} = mod, %StudentClass{} = student_class, student_assignment) do
    changeset = Mod.changeset(%Mod{}, mod)

    Ecto.Multi.new
    |> Ecto.Multi.insert(:mod, changeset)
    |> Ecto.Multi.run(:actions, &insert_public_mod_action(&1.mod, student_class))
    |> Ecto.Multi.run(:self_action, &process_self_action(&1.mod, student_class.id, :manual))
    |> Ecto.Multi.run(:dismissed, &dismiss_mods(student_assignment, mod.assignment_mod_type_id, &1))
    |> Repo.transaction()
  end

  defp publish_mod(%{assignment_mod_type_id: @delete_assignment_mod} = mod, %StudentClass{} = student_class, student_assignment) do
    changeset = Mod.changeset(mod, %{is_private: false})
    
    Ecto.Multi.new
    |> Ecto.Multi.update(:mod, changeset)
    |> Ecto.Multi.run(:actions, &insert_public_mod_action(&1.mod, student_class))
    |> Ecto.Multi.run(:self_action, &process_self_action(&1.mod, student_class.id, :manual))
    |> Ecto.Multi.run(:dismissed, &dismiss_mods(student_assignment, mod.assignment_mod_type_id, &1))
    |> Repo.transaction()
  end

  defp process_existing_mod(mod, %StudentClass{} = student_class, params) do
    case mod.is_private == true and is_private(params["is_private"]) == false do
      true ->
        mod |> publish_mod(student_class)
      false -> 
        Ecto.Multi.new
        |> Ecto.Multi.run(:self_action, process_self_action(mod, student_class.id, :manual))
        |> Ecto.Multi.run(:dismissed, dismiss_prior_mods(mod, student_class.id))
        |> Repo.transaction()
    end
  end

  defp insert_backlogged_actions([], _student_class_id), do: {:ok, nil}
  defp insert_backlogged_actions(enumerable, student_class_id) do
    enumerable
    |> Enum.map(& &1 = Action.changeset(%Action{}, %{is_accepted: nil, assignment_modification_id: &1.id, student_class_id: student_class_id}))
    |> Enum.map(&Repo.insert!(&1))
    |> Enum.find({:ok, nil}, &MapErrors.check_tuple(&1))
  end

  defp insert_backlogged_mods(mod, %StudentClass{} = sc, _) do
    insert_backlogged_mods(mod, sc)
  end

  defp insert_backlogged_mods(mod, %StudentClass{id: id}) do
    mod
    |> get_backlogged_mods()
    |> insert_backlogged_actions(id)
  end

  defp get_backlogged_mods(mod) do
    from(mod in Mod)
    |> where([mod], mod.assignment_id == ^mod.assignment_id)
    |> where([mod], mod.is_private == false)
    |> where([mod], mod.id != ^mod.id)
    |> Repo.all()
  end

  defp insert_public_mod_action(%Mod{is_private: false} = mod, %StudentClass{} = student_class) do
    status = mod
            |> insert_public_mod_action_query(student_class)
            |> Enum.map(&Repo.insert(%Action{assignment_modification_id: mod.id, student_class_id: &1.id, is_accepted: nil}))
    case status |> Enum.find({:ok, nil}, &MapErrors.check_tuple(&1)) do
      {:ok, nil} -> {:ok, status}
      {:error, val} -> {:error, val}
    end
  end

  defp insert_public_mod_action(%Mod{is_private: true}, %StudentClass{}), do: {:ok, nil}

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

  defp process_self_action(%Mod{} = mod, student_class_id, _, atom) do
    process_self_action(mod, student_class_id, atom)
  end

  defp process_self_action(%Mod{id: mod_id}, student_class_id, :manual) do
    case Repo.get_by(Action, assignment_modification_id: mod_id, student_class_id: student_class_id) do
      nil -> Repo.insert(%Action{assignment_modification_id: mod_id, student_class_id: student_class_id, is_accepted: true, is_manual: true})
      val -> val
              |> Ecto.Changeset.change(%{is_accepted: true, is_manual: true})
              |> Repo.update()
    end
  end

  defp process_self_action(%Mod{id: mod_id}, student_class_id, _atom) do
    case Repo.get_by(Action, assignment_modification_id: mod_id, student_class_id: student_class_id) do
      nil -> Repo.insert(%Action{assignment_modification_id: mod_id, student_class_id: student_class_id, is_accepted: true})
      val -> val
              |> Ecto.Changeset.change(%{is_accepted: true, is_manual: false})
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
    |> select([mod, action], action)
    |> Repo.all()
    |> dismiss_from_results()
  end

  defp dismiss_from_results(query) do
    case query do
      [] -> {:ok, nil}
      items -> 
        items = items |> Enum.map(&Repo.update!(Ecto.Changeset.change(&1, %{is_accepted: false, is_manual: false})))
        {:ok, items}
    end
  end

  defp get_data(mod) do
    case mod.assignment_mod_type_id do
      @weight_assignment_mod -> %{weight_id: mod.data |> Map.get("weight_id")}
      @due_assignment_mod -> %{due: mod.data |> Map.get("due") |> get_due_date()}
      @name_assignment_mod -> %{name: mod.data |> Map.get("name")}
    end
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