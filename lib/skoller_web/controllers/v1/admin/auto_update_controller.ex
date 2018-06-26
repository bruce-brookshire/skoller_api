defmodule SkollerWeb.Api.V1.Admin.AutoUpdateController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.Admin.Settings
  alias SkollerWeb.Admin.SettingView
  alias Skoller.Class.Assignment
  alias Skoller.Assignment.Mod
  alias SkollerWeb.Admin.ForecastView
  alias SkollerWeb.Helpers.ModHelper
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Assignments.Mods
  alias Skoller.Students

  import SkollerWeb.Plugs.Auth
  import Ecto.Query
  
  @admin_role 200
  
  @auto_upd_enrollment_threshold "auto_upd_enroll_thresh"
  @auto_upd_response_threshold "auto_upd_response_thresh"
  @auto_upd_approval_threshold "auto_upd_approval_thresh"

  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    settings = Settings.get_auto_update_settings()

    metrics = get_metrics(settings)

    people = get_people()

    items = Map.new()
    |> Map.put(:metrics, metrics)
    |> Map.put(:people, people)
    |> Map.put(:settings, settings)

    render(conn, ForecastView, "show.json", forecast: items)
  end

  def update(conn, %{"settings" => settings}) do

    multi = Ecto.Multi.new()
    |> Ecto.Multi.run(:settings, &update_settings(settings, &1))
   
    case Repo.transaction(multi) do
      {:ok, _params} ->
        process_auto_updates()
        settings = Settings.get_auto_update_settings()
        render(conn, SettingView, "index.json", settings: settings)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def forecast(conn, params) do
    settings = params |> get_settings_from_params()

    metrics = get_metrics(settings)
    
    people = get_people()

    items = Map.new()
    |> Map.put(:metrics, metrics)
    |> Map.put(:people, people)

    render(conn, ForecastView, "show.json", forecast: items)
  end

  defp update_settings(settings, _) do
    status = settings |> Enum.map(&update_setting(&1))
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp update_setting(%{"name" => name} = params) do
    settings_old = Settings.get_setting_by_name!(name)
    Settings.update_setting(settings_old, params)
  end

  defp process_auto_updates() do
    settings = Settings.get_auto_update_settings()
    enrollment_threshold = get_setting(settings, @auto_upd_enrollment_threshold) |> String.to_integer

    Mods.get_non_auto_update_mods_in_enrollment_threshold(enrollment_threshold)
    |> Enum.filter(&compare_shared(&1, settings))
    |> Enum.filter(&compare_responses(&1, settings))
    |> Enum.each(&auto_update_mod(&1))
  end

  defp auto_update_mod(mod) do
    mod = Repo.get!(Mod, mod.assignment_modification_id)
    ModHelper.process_auto_update(mod, :notification)
  end

  defp get_settings_from_params(params) do
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

  defp get_people() do
    Map.new()
    |> Map.put(:creators, Mods.get_creators())
    |> Map.put(:followers, Mods.get_followers())
    |> Map.put(:pending, Mods.get_pending())
    |> Map.put(:joyriders, Mods.get_joyriders())
  end

  defp get_metrics(settings) do
    eligible_communities = get_eligible_communities()
    shared_mods = Mods.get_shared_mods()
    responded_mods = Mods.get_responded_mods()

    approval_threshold = responded_mods |> Enum.filter(&compare_responses(&1, settings))
    response_threshold = shared_mods |> Enum.filter(&compare_shared(&1, settings))
    enrollment_threshold = settings 
                          |> get_setting(@auto_upd_enrollment_threshold)
                          |> String.to_integer()
                          |> get_eligible_communities()

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
    mods = approvals 
    |> Enum.filter(&Enum.any?(responses, fn(x) -> x.mod.id == &1.mod.id end))
    |> List.foldl([], & &2 ++ [&1.mod.id])
    classes = communities |> List.foldl([], & &2 ++ [&1.class_id])

    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> where([m, a], a.class_id in ^classes)
    |> where([m], m.id in ^mods)
    |> select([m], count(m.id))
    |> Repo.one()
  end

  defp compare_responses(item, settings) do
    item.accepted / item.responses >= get_setting(settings, @auto_upd_approval_threshold) |> Float.parse() |> Kernel.elem(0)
  end

  defp compare_shared(item, settings) do
    item.responses / item.audience >= get_setting(settings, @auto_upd_response_threshold) |> Float.parse() |> Kernel.elem(0)
  end

  # defp compare_communities(item, settings) do
  #   item.count >= get_setting(settings, @auto_upd_enrollment_threshold) |> String.to_integer
  # end

  defp get_setting(settings, key) do
    setting = settings |> Enum.find(nil, &key == &1.name)
    setting.value
  end

  defp get_eligible_communities(threshold) do
    from(sc in subquery(Students.get_communities(threshold)))
    |> where([sc], fragment("exists(select 1 from assignment_modifications am inner join assignments a on a.id = am.assignment_id where am.is_private = false and a.class_id = ?)", sc.class_id))
    |> Repo.all()
  end

  defp get_eligible_communities() do
    from(sc in subquery(Students.get_communities()))
    |> where([sc], fragment("exists(select 1 from assignment_modifications am inner join assignments a on a.id = am.assignment_id where am.is_private = false and a.class_id = ?)", sc.class_id))
    |> Repo.all()
  end
end