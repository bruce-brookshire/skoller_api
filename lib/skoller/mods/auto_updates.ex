defmodule Skoller.AutoUpdates do
  @moduledoc """
  The context module for auto updates.
  """

  alias Skoller.Repo
  alias Skoller.Settings
  alias Skoller.ModActions
  alias Skoller.ModNotifications
  alias Skoller.Mods
  alias Skoller.MapErrors

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
      {:ok, %{actions: actions}} -> ModNotifications.send_auto_update_notification(actions)
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
   * `{:ok, %{mod: Skoller.Assignment.Mod, mods: [], actions: [Skoller.Assignment.Mod.Action]}}`
  """
  def process_auto_update(mod) do
    actions = mod |> ModActions.get_enrolled_actions_from_mod()

    update = actions 
    |> Enum.count()
    |> auto_update_count_needed()
    |> auto_update_acted_ratio_needed(actions)
    |> auto_update_copied_ratio_needed()

    case update do
      {:ok, _} ->
        actions = mod |> ModActions.get_actions_from_mod()
        Ecto.Multi.new
        |> Ecto.Multi.run(:mod, &update_mod(mod, &1))
        |> Ecto.Multi.run(:mods, &Mods.apply_mods(actions, &1))
        |> Ecto.Multi.run(:actions, &update_actions(actions, &1))
        |> Repo.transaction()
      {:error, _msg} -> {:ok, nil}
    end
  end

  defp auto_update_count_needed(count) do
    threshold = Settings.get_setting_by_name!(@auto_upd_enrollment_threshold) |> String.to_integer
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

    threshold = Settings.get_setting_by_name!(@auto_upd_response_threshold) |> String.to_float

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

    threshold = Settings.get_setting_by_name!(@auto_upd_approval_threshold) |> String.to_float

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