defmodule Skoller.Admin.Settings do

  alias Skoller.Repo
  alias Skoller.Admin.Setting

  import Ecto.Query

  @auto_upd_topic "AutoUpdate"
  @min_ver_topic "MinVersions"
  @four_door_topic "FourDoor"

  def get_auto_update_settings() do
    from(s in Setting)
    |> where([s], s.topic == @auto_upd_topic)
    |> Repo.all()
  end

  def get_min_ver_settings() do
    from(s in Setting)
    |> where([s], s.topic == @min_ver_topic)
    |> Repo.all()
  end

  def get_four_door_settings() do
    from(s in Setting)
    |> where([s], s.topic == @four_door_topic)
    |> Repo.all()
  end

  def get_setting_by_name!(name) do
    Repo.get!(Setting, name)
  end

  def update_setting(old, params) do
    Setting.changeset_update(old, params)
    |> Repo.update()
  end
end