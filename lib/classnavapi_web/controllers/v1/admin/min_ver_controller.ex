defmodule ClassnavapiWeb.Api.V1.Admin.MinVerController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Admin.Settings
  alias ClassnavapiWeb.Admin.SettingView

  import ClassnavapiWeb.Helpers.AuthPlug

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def update(conn, %{"name" => name} = params) do
    old_setting = Settings.get_setting_by_name!(name)
    case Settings.update_setting(old_setting, params) do
      {:ok, setting} ->
        render(conn, SettingView, "show.json", setting: setting)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end