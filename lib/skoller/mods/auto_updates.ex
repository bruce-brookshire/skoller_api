defmodule Skoller.AutoUpdates do
  @moduledoc """
  The context module for auto updates.
  """

  # TODO: Combine auto update logic into one set of functions instead of the current two.

  alias Skoller.Mods.Mod
  alias Skoller.Repo
  alias Skoller.Settings
  alias Skoller.ModActions
  alias Skoller.ModNotifications
  alias Skoller.Mods
  alias Skoller.MapErrors
  alias Skoller.Mods.Action
  alias Skoller.EnrolledStudents
  alias Skoller.StudentClasses
  alias Skoller.Mods.StudentClasses, as: ModStudentClasses
  alias Skoller.Mods.Classes

  import Ecto.Query

  require Logger

  @auto_upd_enrollment_threshold "auto_upd_enroll_thresh"
  @auto_upd_response_threshold "auto_upd_response_thresh"
  @auto_upd_approval_threshold "auto_upd_approval_thresh"

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
  def process_auto_update(mod, opts \\ []) do
    Logger.info("Beginning auto update check for mod: " <> to_string(mod.id))
    case check_auto_update_criteria(mod) do
      {:ok, _} ->
        Logger.info("Beginning auto update for mod: " <> to_string(mod.id))
        result = mod
        |> auto_update_mod()
        |> check_notification(opts)
        result
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
    |> join(:inner, [a], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), on: sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(EnrolledStudents.get_communities()), on: cm.class_id == sc.class_id)
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
    |> join(:inner, [a], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), on: sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(EnrolledStudents.get_communities()), on: cm.class_id == sc.class_id)
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
    |> join(:inner, [a], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), on: sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(EnrolledStudents.get_communities()), on: cm.class_id == sc.class_id)
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
    |> join(:inner, [m], sc in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), on: sc.student_id == m.student_id)
    |> join(:inner, [m, sc], cm in subquery(EnrolledStudents.get_communities()), on: cm.class_id == sc.class_id)
    |> distinct([m], m.student_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets metrics on auto updates based on `settings`.

  ## Returns
  `%{metrics: %{max_metrics, actual_metrics, summary}, people: %{creators, followers, pending, joyriders}, settings}`
  """
  def get_auto_update_metrics(settings) do
    metrics = get_metrics(settings)

    people = Map.new()
    |> Map.put(:creators, get_creators())
    |> Map.put(:followers, get_followers())
    |> Map.put(:pending, get_pending())
    |> Map.put(:joyriders, get_joyriders())

    Map.new()
    |> Map.put(:metrics, metrics)
    |> Map.put(:people, people)
    |> Map.put(:settings, settings)
  end

  @doc """
  Processes auto updates on all mods, and sends notifications if any are updated.
  """
  def process_auto_updates_all_mods() do
    settings = Settings.get_auto_update_settings()
    enrollment_threshold = get_setting_value(settings, @auto_upd_enrollment_threshold) |> String.to_integer

    ModActions.get_non_auto_update_mod_actions_in_enrollment_threshold(enrollment_threshold)
    |> Enum.filter(&compare_shared(&1, settings))
    |> Enum.filter(&compare_responses(&1, settings))
    |> Enum.each(&get_and_auto_update_mod(&1))
  end

  @doc """
  Gets auto update settings by params. If there are missing params, defaults are fetched.
  """
  def get_settings_from_params_or_default(params) do
    get_enroll_thresh(params) ++ get_response_thresh(params) ++ get_approval_thresh(params)
  end

  defp get_approval_thresh(%{@auto_upd_approval_threshold => val}) do
    Map.new()
    |> Map.put(:name, @auto_upd_approval_threshold)
    |> Map.put(:value, val)
    |> List.wrap()
  end
  defp get_approval_thresh(_params) do
    Map.new()
    |> Map.put(:name, @auto_upd_approval_threshold)
    |> Map.put(:value, Settings.get_setting_by_name!(@auto_upd_approval_threshold).value)
    |> List.wrap()
  end

  defp get_response_thresh(%{@auto_upd_response_threshold => val}) do
    Map.new()
    |> Map.put(:name, @auto_upd_response_threshold)
    |> Map.put(:value, val)
    |> List.wrap()
  end
  defp get_response_thresh(_params) do
    Map.new()
    |> Map.put(:name, @auto_upd_response_threshold)
    |> Map.put(:value, Settings.get_setting_by_name!(@auto_upd_response_threshold).value)
    |> List.wrap()
  end

  defp get_enroll_thresh(%{@auto_upd_enrollment_threshold => val}) do
    Map.new()
    |> Map.put(:name, @auto_upd_enrollment_threshold)
    |> Map.put(:value, val)
    |> List.wrap()
  end
  defp get_enroll_thresh(_params) do
    Map.new()
    |> Map.put(:name, @auto_upd_enrollment_threshold)
    |> Map.put(:value, Settings.get_setting_by_name!(@auto_upd_enrollment_threshold).value)
    |> List.wrap()
  end

  defp get_and_auto_update_mod(mod) do
    Mods.get_mod!(mod.assignment_modification_id)
    |> process_auto_update([notification: true])
  end

  defp get_metrics(settings) do
    eligible_communities = ModStudentClasses.get_communities_with_mods()
    shared_mods = ModActions.get_shared_mods()
    responded_mods = ModActions.get_responded_mods()

    approval_threshold = responded_mods |> Enum.filter(&compare_responses(&1, settings))
    response_threshold = shared_mods |> Enum.filter(&compare_shared(&1, settings))
    enrollment_threshold = settings 
                          |> get_setting_value(@auto_upd_enrollment_threshold)
                          |> String.to_integer()
                          |> ModStudentClasses.get_communities_with_mods()

    max_metrics = Map.new()
    |> Map.put(:eligible_communities, eligible_communities |> Enum.count())
    |> Map.put(:shared_mods, shared_mods |> Enum.count())
    |> Map.put(:responded_mods, responded_mods |> Enum.count())

    actual_metrics = Map.new()
    |> Map.put(:eligible_communities, enrollment_threshold |> Enum.count())
    |> Map.put(:shared_mods, response_threshold |> Enum.count())
    |> Map.put(:responded_mods, approval_threshold |> Enum.count())

    summary = get_summary(enrollment_threshold, response_threshold, approval_threshold)

    Map.new()
    |> Map.put(:max_metrics, max_metrics)
    |> Map.put(:actual_metrics, actual_metrics)
    |> Map.put(:summary, summary)
  end

  defp get_summary(communities, responses, approvals) do
    # Gets a list of mod ids from approvals cross checked by responses.
    mods = approvals 
    |> Enum.filter(&Enum.any?(responses, fn(x) -> x.mod.id == &1.mod.id end))
    |> List.foldl([], & &2 ++ [&1.mod.id])

    # Gets a list of class ids from communities.
    classes = communities |> List.foldl([], & &2 ++ [&1.class_id])

    Classes.get_count_of_mods_in_classes(mods, classes)
  end

  defp auto_update_mod(mod) do
    Ecto.Multi.new
    |> Ecto.Multi.run(:mod, fn (_, changes) -> update_mod(mod, changes) end)
    |> Ecto.Multi.run(:actions, fn (_, changes) -> apply_mod_from_actions(changes.mod) end)
    |> Repo.transaction()
  end

  defp check_auto_update_criteria(mod) do
    actions = mod |> ModActions.get_enrolled_actions_from_mod()

    actions
    |> Enum.count()
    |> auto_update_count_needed()
    |> auto_update_acted_ratio_needed(actions)
    |> auto_update_copied_ratio_needed()
  end

  defp check_notification({:ok, %{actions: actions, mod: mod}}, opts) do
    if Keyword.get(opts, :notification, false) do
      Logger.info("Preparing auto update notifications for mod: " <> to_string(mod.id))
      Task.start(ModNotifications, :send_auto_update_notification, [actions])
    end
  end
  defp check_notification(_results, _opts), do: {:ok, nil}

  # Applies all actions that are currently nil for mod.
  defp apply_mod_from_actions(mod) do
    status = mod
    |> ModActions.get_actions_from_mod()
    |> Enum.filter(&is_nil(&1.is_accepted))
    |> Enum.map(&apply_mod_from_action(&1, mod))
    
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  defp apply_mod_from_action(action, mod) do
    student_class = StudentClasses.get_student_class_by_id!(action.student_class_id)
    mod
    |> Mods.apply_mod(student_class, [manual: false])
  end

  defp auto_update_count_needed(count) do
    threshold = Settings.get_setting_by_name!(@auto_upd_enrollment_threshold).value |> String.to_integer
    case count < threshold do
      true -> {:error, :not_enough_enrolled}
      false -> {:ok, count}
    end
  end

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
  defp auto_update_acted_ratio_needed(result, _count), do: result

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
  defp auto_update_copied_ratio_needed(result), do: result

  defp update_mod(mod, _) do
    Mods.update_mod(mod, %{is_auto_update: true})
  end

  defp compare_responses(item, settings) do
    item.accepted / item.responses >= get_setting_value(settings, @auto_upd_approval_threshold) |> Float.parse() |> Kernel.elem(0)
  end

  defp compare_shared(item, settings) do
    item.responses / item.audience >= get_setting_value(settings, @auto_upd_response_threshold) |> Float.parse() |> Kernel.elem(0)
  end

  defp get_setting_value(settings, key) do
    setting = settings |> Enum.find(nil, &key == &1.name)
    setting.value
  end
end