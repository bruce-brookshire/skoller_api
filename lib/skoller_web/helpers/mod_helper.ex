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

  import Ecto.Query

  @new_assignment_mod 400

  def apply_mod(_mod, _student_class, _atom \\ :manual) do

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
end