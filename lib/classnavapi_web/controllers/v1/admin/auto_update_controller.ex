defmodule ClassnavapiWeb.Api.V1.Admin.AutoUpdateController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Admin.Settings
  alias ClassnavapiWeb.Admin.SettingView
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Assignment.Mod
  alias Classnavapi.Assignment.Mod.Action
  alias ClassnavapiWeb.Admin.ForecastView
  alias ClassnavapiWeb.Helpers.ModHelper
  alias ClassnavapiWeb.Helpers.RepoHelper

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @admin_role 200

  @community 2
  
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

    from(m in Mod)
    |> join(:inner, [m], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> join(:inner, [m, act], a in Assignment, a.id == m.assignment_id)
    |> where([m], m.is_auto_update == false and m.is_private == false)
    |> where([m, act, a], fragment("exists (select 1 from student_classes sc where sc.class_id = ? group by class_id having count(1) > ?)", a.class_id, ^enrollment_threshold))
    |> select([m, act], act)
    |> Repo.all()
    |> Enum.filter(&compare_shared(&1, settings))
    |> Enum.filter(&compare_responses(&1, settings))
    |> Enum.each(&auto_update_mod(&1))
  end

  defp auto_update_mod(mod) do
    Repo.get!(Mod, mod.assignment_modification_id)
    |> ModHelper.auto_update_mod()
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
    |> Map.put(:creators, get_creators())
    |> Map.put(:followers, get_followers())
    |> Map.put(:pending, get_pending())
    |> Map.put(:joyriders, get_joyriders())
  end

  defp get_joyriders() do
    from(a in Action)
    |> join(:inner, [a], sc in StudentClass, sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(community_sub(@community)), cm.class_id == sc.class_id)
    |> where([a], a.is_accepted == true and a.is_manual == false)
    |> where([a, sc], sc.is_dropped == false)
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  defp get_pending() do
    from(a in Action)
    |> join(:inner, [a], sc in StudentClass, sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(community_sub(@community)), cm.class_id == sc.class_id)
    |> where([a], is_nil(a.is_accepted))
    |> where([a, sc], sc.is_dropped == false)
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  defp get_followers() do
    from(a in Action)
    |> join(:inner, [a], sc in StudentClass, sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(community_sub(@community)), cm.class_id == sc.class_id)
    |> where([a], a.is_manual == true and a.is_accepted == true)
    |> where([a, sc], sc.is_dropped == false)
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  defp get_creators() do
    from(m in Mod)
    |> join(:inner, [m], sc in StudentClass, sc.student_id == m.student_id)
    |> join(:inner, [m, sc], cm in subquery(community_sub(@community)), cm.class_id == sc.class_id)
    |> distinct([m], m.student_id)
    |> Repo.aggregate(:count, :id)
  end

  defp get_metrics(settings) do
    eligible_communities = get_eligible_communities(@community)
    shared_mods = get_shared_mods()
    responded_mods = get_responded_mods()

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

  defp get_responded_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(community_sub(@community)), sc.class_id == a.class_id)
    |> join(:inner, [m, a, sc], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> where([m], m.is_private == false)
    |> where([m], fragment("exists(select 1 from modification_actions ma inner join student_classes sc on sc.id = ma.student_class_id where sc.is_dropped = false and ma.is_accepted = true and ma.assignment_modification_id = ? and sc.student_id != ?)", m.id, m.student_id))
    |> select([m, a, sc, act], %{mod: m, responses: act.responses, accepted: act.accepted})
    |> Repo.all()
  end

  defp get_shared_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(community_sub(@community)), sc.class_id == a.class_id)
    |> join(:inner, [m, a, sc], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> where([m], m.is_private == false)
    |> select([m, a, sc, act], %{mod: m, responses: act.responses, audience: act.audience})
    |> Repo.all()
  end

  defp get_eligible_communities(threshold) do
    from(sc in subquery(community_sub(threshold)))
    |> where([sc], fragment("exists(select 1 from assignment_modifications am inner join assignments a on a.id = am.assignment_id where am.is_private = false and a.class_id = ?)", sc.class_id))
    |> Repo.all()
  end

  defp mod_responses_sub() do
    from(a in Action)
    |> group_by([a], a.assignment_modification_id)
    |> select([a], %{assignment_modification_id: a.assignment_modification_id, responses: count(a.is_accepted), audience: count(a.id), accepted: sum(fragment("?::int", a.is_accepted))})
  end

  defp community_sub(threshold) do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
    |> group_by([sc], sc.class_id)
    |> having([sc], count(sc.id) >= ^threshold)
    |> select([sc], %{class_id: sc.class_id, count: count(sc.id)})
  end
end