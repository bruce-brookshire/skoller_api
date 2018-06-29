defmodule Skoller.Settings do
  @moduledoc """
  The context module for Admin Settings.
  """

  #TODO: this can be split into a context for each kind of setting

  alias Skoller.Repo
  alias Skoller.Settings.Setting

  import Ecto.Query

  @auto_upd_topic "AutoUpdate"
  @min_ver_topic "MinVersions"
  @four_door_topic "FourDoor"

  @doc """
  Gets the current auto update settings from admin_settings.

  Returns `[Skoller.Settings.Setting]` or `[]`
  """
  def get_auto_update_settings() do
    from(s in Setting)
    |> where([s], s.topic == @auto_upd_topic)
    |> Repo.all()
  end

  @doc """
  Gets the current minimum version settings from admin_settings.

  Returns `[Skoller.Settings.Setting]` or `[]`
  """
  def get_min_ver_settings() do
    from(s in Setting)
    |> where([s], s.topic == @min_ver_topic)
    |> Repo.all()
  end

  @doc """
  Gets the current four door settings from admin_settings.

  Returns `[Skoller.Settings.Setting]` or `[]`
  """
  def get_four_door_settings() do
    from(s in Setting)
    |> where([s], s.topic == @four_door_topic)
    |> Repo.all()
  end

  @doc """
  Gets the a setting by name from admin_settings.

  If `name` does not exist, an error will be thrown

  Returns `Skoller.Settings.Setting` or `Ecto.NoResultsError`
  """
  def get_setting_by_name!(name) do
    Repo.get!(Setting, name)
  end

  @doc """
  Updates an admin setting.

  `setting` must be of type `Skoller.Settings.Setting`.

  Returns `{:ok, Skoller.Settings.Setting}` or `{:error, Ecto.Changeset}`
  """
  def update_setting(%Setting{} = setting, params) do
    Setting.changeset_update(setting, params)
    |> Repo.update()
  end
end