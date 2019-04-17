defmodule Skoller.Settings do
  @moduledoc """
  The context module for Admin Settings.
  """

  #TODO: this can be split into a context for each kind of setting

  alias Skoller.Repo
  alias Skoller.Settings.Setting
  alias Skoller.MapErrors

  import Ecto.Query

  @auto_upd_topic "AutoUpdate"
  @min_ver_topic "MinVersions"
  @four_door_topic "FourDoor"
  @notification_topic "Notification"

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
  Gets the current notification settings from admin_settings.

  Returns `[Skoller.Settings.Setting]` or `[]`
  """
  def get_notification_settings() do
    from(s in Setting)
    |> where([s], s.topic == @notification_topic)
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
  Updates multiple settings.

  ## Returns
  `%{:ok, settings: []}`, or an `Ecto.Multi` error struct.
  """
  def update_settings(settings) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:settings, fn (_, changes) -> multi_update_settings(settings, changes) end)
    |> Repo.transaction()
  end

  defp multi_update_settings(settings, _) do
    status = settings |> Enum.map(&process_multi_update_setting(&1))
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  defp process_multi_update_setting(%{"name" => name, "value" => value}) do
    get_setting_by_name!(name)
    |> Setting.changeset_update(%{value: value |> to_string()})
    |> Repo.update()
  end
end