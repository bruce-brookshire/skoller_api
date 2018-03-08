defmodule ClassnavapiWeb.Api.V1.Admin.AutoUpdateController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Admin.Settings
  alias ClassnavapiWeb.Admin.SettingView
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Assignment.Mod

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @admin_role 200

  @community 2

  plug :verify_role, %{role: @admin_role}

  def index(conn, _params) do
    settings = Settings.get_auto_update_settings()

    eligible_communities = get_eligible_communities()
    shared_mods = get_shared_mods()
    responded_mods = get_responded_mods()

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

  defp get_responded_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(community_sub()), sc.class_id == a.class_id)
    |> where([m], m.is_private == false)
    |> where([m], fragment("exists(select 1 from modification_actions ma inner join student_classes sc on sc.id = ma.student_class_id where sc.is_dropped = false and ma.is_accepted is not null and ma.assignment_modification_id = ? and sc.student_id != ?)", m.id, m.student_id))
    |> select([m], count(m.id))
    |> Repo.one()
  end

  defp get_shared_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(community_sub()), sc.class_id == a.class_id)
    |> where([m], m.is_private == false)
    |> select([m], count(m.id))
    |> Repo.one()
  end

  defp get_eligible_communities() do
    from(sc in subquery(community_sub()))
    |> where([sc], fragment("exists(select 1 from assignment_modifications am inner join assignments a on a.id = am.assignment_id where am.is_private = false and a.class_id = ?)", sc.class_id))
    |> select([sc], count(sc.class_id))
    |> Repo.one()
  end

  defp community_sub() do
    from(sc in StudentClass)
    |> where([sc], sc.is_dropped == false)
    |> group_by([sc], sc.class_id)
    |> having([sc], count(sc.id) >= @community)
    |> select([sc], %{class_id: sc.class_id, count: count(sc.id)})
  end
end