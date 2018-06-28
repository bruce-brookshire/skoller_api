defmodule SkollerWeb.Helpers.ModHelper do
  use SkollerWeb, :controller

  @moduledoc """
  
  Helper for inserting mods.

  """

  alias Skoller.Class.Assignment
  alias Skoller.Assignment.Mod
  alias Skoller.Assignment.Mod.Action
  alias Skoller.Repo
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.StudentAssignments.StudentAssignment
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Helpers.NotificationHelper
  alias Skoller.Admin.Settings
  alias Skoller.StudentAssignments

  import Ecto.Query

  @name_assignment_mod 100
  @weight_assignment_mod 200
  @due_assignment_mod 300
  @new_assignment_mod 400
  @delete_assignment_mod 500

  @auto_upd_enrollment_threshold "auto_upd_enroll_thresh"
  @auto_upd_response_threshold "auto_upd_response_thresh"
  @auto_upd_approval_threshold "auto_upd_approval_thresh"

  def apply_mod(%Mod{} = mod, %StudentClass{} = student_class, :auto) do
    case mod.assignment_mod_type_id do
      @delete_assignment_mod -> apply_delete_mod(mod, student_class, :auto)
      @new_assignment_mod -> apply_new_mod(mod, student_class, :auto)
      _ -> apply_change_mod(mod, student_class, :auto)
    end
  end
  def apply_mod(%Mod{} = mod, %StudentClass{} = student_class) do
    case mod.assignment_mod_type_id do
      @delete_assignment_mod -> apply_delete_mod(mod, student_class, :manual)
      @new_assignment_mod -> apply_new_mod(mod, student_class, :manual)
      _ -> apply_change_mod(mod, student_class, :manual)
    end
  end

  def pending_mods_for_assignment(%StudentAssignment{} = student_assignment) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, m.id == act.assignment_modification_id and act.student_class_id == ^student_assignment.student_class_id)
    |> where([m], m.assignment_id == ^student_assignment.assignment_id)
    |> where([m, act], is_nil(act.is_accepted))
    |> Repo.all
  end

  def pending_mods_for_assignment(%{student_class_id: student_class_id, assignment_id: assignment_id}) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, m.id == act.assignment_modification_id and act.student_class_id == ^student_class_id)
    |> where([m], m.assignment_id == ^assignment_id)
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

  def process_auto_update(mod, :notification) do
    case mod |> process_auto_update() do
      {:ok, nil} -> {:ok, nil}
      {:ok, %{actions: actions}} -> NotificationHelper.send_auto_update_notification(actions)
    end
  end

  def process_auto_update(mod) do
    actions = mod |> get_enrolled_actions_from_mod()
    settings = Settings.get_auto_update_settings()

    update = actions 
    |> Enum.count()
    |> auto_update_count_needed(settings)
    |> auto_update_acted_ratio_needed(actions, settings)
    |> auto_update_copied_ratio_needed(settings)

    case update do
      {:ok, _} ->
        actions = mod |> get_actions_from_mod()
        Ecto.Multi.new
        |> Ecto.Multi.run(:mod, &update_mod(mod, &1))
        |> Ecto.Multi.run(:mods, &apply_mods(actions, &1))
        |> Ecto.Multi.run(:actions, &update_actions(actions, &1))
        |> Repo.transaction()
      {:error, _msg} -> {:ok, nil}
    end
  end

  defp update_mod(mod, _) do
    Ecto.Changeset.change(mod, %{is_auto_update: true})
    |> Repo.update()
  end

  defp apply_action_mods(action) do
    student_class = Repo.get!(StudentClass, action.student_class_id)
    mod = Repo.get!(Mod, action.assignment_modification_id)
    Repo.transaction(apply_mod(mod, student_class, :auto))
  end

  defp apply_mods(actions, _) do
    nil_actions = actions |> Enum.filter(&is_nil(&1.is_accepted))

    status = nil_actions |> Enum.map(&apply_action_mods(&1))
    
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp update_actions({:error, msg}, _actions), do: {:error, msg}
  defp update_actions(actions, _) do
    nil_actions = actions |> Enum.filter(&is_nil(&1.is_accepted))
    
    status = nil_actions |> Enum.map(&update_action(&1))
    
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp update_action(%Action{} = action) do
    action
    |> Ecto.Changeset.change(%{is_accepted: true, is_manual: false})
    |> Repo.update()
  end

  defp get_setting(settings, key) do
    setting = settings |> Enum.find(nil, &key == &1.name)
    setting.value
  end

  defp auto_update_count_needed(count, settings) do
    threshold = settings |> get_setting(@auto_upd_enrollment_threshold) |> String.to_integer
    case count < threshold do
      true -> {:error, :not_enough_enrolled}
      false -> {:ok, count}
    end
  end
  
  defp auto_update_copied_ratio_needed({:error, msg}, _settings), do: {:error, msg}
  defp auto_update_copied_ratio_needed({:ok, acted}, settings) do
    count = acted |> Enum.count()

    action_count = acted
    |> Enum.filter(& &1.is_accepted == true)
    |> Enum.count()

    threshold = settings |> get_setting(@auto_upd_approval_threshold) |> String.to_float

    case action_count / count < threshold do
      true -> {:error, :not_enough_copied}
      false -> {:ok, nil}
    end
  end

  defp auto_update_acted_ratio_needed({:error, msg}, _count, _settings), do: {:error, msg}
  defp auto_update_acted_ratio_needed({:ok, count}, actions, settings) do
    acted = actions
    |> Enum.filter(& not(is_nil(&1.is_accepted)))

    action_count = acted
    |> Enum.count()

    threshold = settings |> get_setting(@auto_upd_response_threshold) |> String.to_float

    case action_count / count < threshold do
      true -> {:error, :not_enough_responses}
      false -> {:ok, acted}
    end
  end

  defp get_actions_from_mod(%Mod{id: id}) do
    from(act in Action)
    |> where([act], act.assignment_modification_id == ^id)
    |> Repo.all()
  end
  defp get_actions_from_mod(_mod), do: []

  defp get_enrolled_actions_from_mod(%Mod{id: id}) do
    from(act in Action)
    |> join(:inner, [act], sc in StudentClass, sc.id == act.student_class_id)
    |> where([act], act.assignment_modification_id == ^id)
    |> where([act, sc], sc.is_dropped == false)
    |> Repo.all()
  end
  defp get_enrolled_actions_from_mod(_mod), do: []

  defp apply_delete_mod(%Mod{} = mod, %StudentClass{id: id}, atom) do
    student_assignment = Repo.get_by!(StudentAssignment, assignment_id: mod.assignment_id, student_class_id: id)

    Ecto.Multi.new
    |> Ecto.Multi.delete(:student_assignment, student_assignment)
    |> Ecto.Multi.run(:self_action, &process_self_action(mod, &1.student_assignment.student_class_id, atom))
    |> Ecto.Multi.run(:dismissed, &dismiss_mods(student_assignment, mod.assignment_mod_type_id, &1))
  end

  defp apply_new_mod(%Mod{} = mod, %StudentClass{} = student_class, atom) do
    student_assignment = Assignment
    |> Repo.get!(mod.assignment_id)
    |> StudentAssignments.convert_assignment(student_class)

    Ecto.Multi.new
    |> Ecto.Multi.run(:student_assignment, &insert_student_assignment(student_assignment, &1))
    |> Ecto.Multi.run(:backfill_mods, &backfill_mods(&1.student_assignment))
    |> Ecto.Multi.run(:self_action, &process_self_action(mod, &1.student_assignment.student_class_id, atom))
    |> Ecto.Multi.run(:dismissed, &dismiss_mods(&1.student_assignment, @delete_assignment_mod))
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
    
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp insert_student_assignment(student_assignment, _) do
    case StudentAssignments.get_assignment_by_ids(student_assignment.assignment_id, student_assignment.student_class_id) do
      nil -> Repo.insert(student_assignment)
      assign -> {:ok, assign}
    end
  end

  defp apply_change_mod(%Mod{} = mod, %StudentClass{id: id}, atom) do
    student_assignment = Repo.get_by!(StudentAssignment, assignment_id: mod.assignment_id, student_class_id: id)

    mod_change = mod
    |> get_data()

    Ecto.Multi.new
    |> Ecto.Multi.update(:student_assignment, Ecto.Changeset.change(student_assignment, mod_change))
    |> Ecto.Multi.run(:self_action, &process_self_action(mod, &1.student_assignment.student_class_id, atom))
    |> Ecto.Multi.run(:dismissed, &dismiss_prior_mods(mod, &1.student_assignment.student_class_id))
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

  defp dismiss_mods(%StudentAssignment{} = student_assignment, @delete_assignment_mod, _) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, mod.id == action.assignment_modification_id and action.student_class_id == ^student_assignment.student_class_id)
    |> where([mod], mod.assignment_mod_type_id != @delete_assignment_mod)
    |> where([mod], mod.assignment_id == ^student_assignment.assignment_id)
    |> select([mod, action], action)
    |> Repo.all()
    |> dismiss_from_results()
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

  defp dismiss_from_results(query) do
    case query do
      [] -> {:ok, nil}
      items -> 
        items = items |> Enum.map(&Repo.update!(Ecto.Changeset.change(&1, %{is_accepted: false, is_manual: false})))
        {:ok, items}
    end
  end
end