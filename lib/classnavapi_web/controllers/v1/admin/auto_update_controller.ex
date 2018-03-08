defmodule ClassnavapiWeb.Api.V1.Admin.AutoUpdateController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Admin.Settings
  alias ClassnavapiWeb.Admin.SettingView
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Assignment.Mod
  alias Classnavapi.Assignment.Mod.Action

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

    render(conn, SettingView, "index.json", settings: settings)
  end

  def update(conn, %{"id" => id} = params) do
    settings_old = Settings.get_setting_by_name!(id)
    case Settings.update_setting(settings_old, params) do
      {:ok, setting} ->
        render(conn, SettingView, "show.json", setting: setting)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def forecast(conn, params) do
    
  end

  defp get_metrics(settings) do
    eligible_communities = get_eligible_communities()
    shared_mods = get_shared_mods()
    responded_mods = get_responded_mods()

    approval_threshold = responded_mods |> Enum.filter(&compare_responses(&1, settings))
    response_threshold = shared_mods |> Enum.filter(&compare_shared(&1, settings))
    enrollment_threshold = eligible_communities |> Enum.filter(&compare_communities(&1, settings))
    
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
    item.accepted / item.responses >= get_setting(settings, @auto_upd_approval_threshold) |> String.to_float
  end

  defp compare_shared(item, settings) do
    item.responses / item.all >= get_setting(settings, @auto_upd_response_threshold) |> String.to_float
  end

  defp compare_communities(item, settings) do
    item.count >= get_setting(settings, @auto_upd_enrollment_threshold) |> String.to_integer
  end

  defp get_setting(settings, key) do
    setting = settings |> Enum.find(nil, &key == &1.name)
    setting.value
  end

  defp get_responded_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(community_sub()), sc.class_id == a.class_id)
    |> join(:inner, [m, a, sc], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> where([m], m.is_private == false)
    |> where([m], fragment("exists(select 1 from modification_actions ma inner join student_classes sc on sc.id = ma.student_class_id where sc.is_dropped = false and ma.is_accepted is not null and ma.assignment_modification_id = ? and sc.student_id != ?)", m.id, m.student_id))
    |> select([m, a, sc, act, all], %{mod: m, responses: act.responses, accepted: act.accepted})
    |> Repo.all()
  end

  defp get_shared_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(community_sub()), sc.class_id == a.class_id)
    |> join(:inner, [m, a, sc], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> where([m], m.is_private == false)
    |> select([m, a, sc, act, all], %{mod: m, responses: act.responses, all: act.audience})
    |> Repo.all()
  end

  defp get_eligible_communities() do
    from(sc in subquery(community_sub()))
    |> where([sc], fragment("exists(select 1 from assignment_modifications am inner join assignments a on a.id = am.assignment_id where am.is_private = false and a.class_id = ?)", sc.class_id))
    |> Repo.all()
  end

  defp mod_responses_sub() do
    from(a in Action)
    |> group_by([a], a.assignment_modification_id)
    |> select([a], %{assignment_modification_id: a.assignment_modification_id, responses: count(a.is_accepted), audience: count(a.id), accepted: sum(fragment("?::int", a.is_accepted))})
  end

  defp community_sub() do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
    |> group_by([sc], sc.class_id)
    |> having([sc], count(sc.id) >= @community)
    |> select([sc], %{class_id: sc.class_id, count: count(sc.id)})
  end
end