defmodule Skoller.AutoUpdates do
  @moduledoc """
  The context module for auto updates.
  """

  alias Skoller.Mods.Mod
  alias Skoller.Repo
  alias Skoller.Settings
  alias Skoller.ModActions
  alias Skoller.ModNotifications
  alias Skoller.Mods
  alias Skoller.MapErrors
  alias Skoller.Mods.Action
  alias Skoller.EnrolledStudents
  alias Skoller.Students

  import Ecto.Query

  require Logger

  @auto_upd_enrollment_threshold "auto_upd_enroll_thresh"
  @auto_upd_response_threshold "auto_upd_response_thresh"
  @auto_upd_approval_threshold "auto_upd_approval_thresh"

  @doc """
  See `process_auto_update/1`. Also sends notificaitons on success.

  For use in a Task.
  """
  def process_auto_update(mod, :notification) do
    case mod |> process_auto_update() do
      {:ok, nil} -> {:ok, nil}
      {:ok, %{actions: actions}} -> 
        Logger.info("Preparing auto update notifications for mod: " <> to_string(mod.id))
        ModNotifications.send_auto_update_notification(actions)
    end
  end

  @doc """
  Processes auto updates if a mod meets the right criteria.

  See `Skoller.Mods.apply_mod/3` for the `:mods` return field.

  ## Settings
  There are admin settings that dictate whether or not mods fall under update criteria, including
   * enrollment
   * acceptance rate
   * response rate

  ## Behavior
  Auto updates are when anyone that has still not answered a mod will be updated as if they had accepted the mod.

  ## Returns
   * `{:ok, nil}` if there is no auto update needed
   * `{:ok, %{mod: Skoller.Mods.Mod, mods: [], actions: [Skoller.Mods.Action]}}`
  """
  def process_auto_update(mod) do
    Logger.info("Beginning auto update check for mod: " <> to_string(mod.id))
    actions = mod |> ModActions.get_enrolled_actions_from_mod()

    update = actions 
    |> Enum.count()
    |> auto_update_count_needed()
    |> auto_update_acted_ratio_needed(actions)
    |> auto_update_copied_ratio_needed()

    case update do
      {:ok, _} ->
        Logger.info("Beginning auto update for mod: " <> to_string(mod.id))
        actions = mod |> ModActions.get_actions_from_mod()
        Ecto.Multi.new
        |> Ecto.Multi.run(:mod, &update_mod(mod, &1))
        |> Ecto.Multi.run(:mods, &Mods.apply_mods(actions, &1))
        |> Ecto.Multi.run(:actions, &update_actions(actions, &1))
        |> Repo.transaction()
      {:error, _msg} -> {:ok, nil}
    end
  end

  @doc """
  Gets the count of joyriders.

  Joyriders are students in communities that have autoupdated mods.

  ## Returns
  `Integer`
  """
  def get_joyriders() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> where([a], a.is_accepted == true and a.is_manual == false)
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the count of pending students.

  Pending students are students in communities with mods that they have not responded to yet.

  ## Returns
  `Integer`
  """
  def get_pending() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> where([a], is_nil(a.is_accepted))
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the count of followers.

  Followers are students in communities with mods that they accepted.

  ## Returns
  `Integer`
  """
  def get_followers() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> where([a], a.is_manual == true and a.is_accepted == true)
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the count of creators.

  Creators are students in communities that creates a mod.

  ## Returns
  `Integer`
  """
  def get_creators() do
    from(m in Mod)
    |> join(:inner, [m], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), sc.student_id == m.student_id)
    |> join(:inner, [m, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> distinct([m], m.student_id)
    |> Repo.aggregate(:count, :id)
  end

  defp auto_update_count_needed(count) do
    threshold = Settings.get_setting_by_name!(@auto_upd_enrollment_threshold).value |> String.to_integer
    case count < threshold do
      true -> {:error, :not_enough_enrolled}
      false -> {:ok, count}
    end
  end

  defp auto_update_acted_ratio_needed({:error, msg}, _count), do: {:error, msg}
  defp auto_update_acted_ratio_needed({:ok, count}, actions) do
    acted = actions
    |> Enum.filter(& not(is_nil(&1.is_accepted)))

    action_count = acted
    |> Enum.count()

    threshold = Settings.get_setting_by_name!(@auto_upd_response_threshold).value |> String.to_float

    case action_count / count < threshold do
      true -> {:error, :not_enough_responses}
      false -> {:ok, acted}
    end
  end

  defp auto_update_copied_ratio_needed({:error, msg}), do: {:error, msg}
  defp auto_update_copied_ratio_needed({:ok, acted}) do
    count = acted |> Enum.count()

    action_count = acted
    |> Enum.filter(& &1.is_accepted == true)
    |> Enum.count()

    threshold = Settings.get_setting_by_name!(@auto_upd_approval_threshold).value |> String.to_float

    case action_count / count < threshold do
      true -> {:error, :not_enough_copied}
      false -> {:ok, nil}
    end
  end

  defp update_actions(actions, _) do
    nil_actions = actions |> Enum.filter(&is_nil(&1.is_accepted))
    
    status = nil_actions |> Enum.map(&ModActions.update_action(&1, %{is_accepted: true, is_manual: false}))
    
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  defp update_mod(mod, _) do
    Mods.update_mod(mod, %{is_auto_update: true})
  end
end