defmodule Skoller.Settings do
  @moduledoc """
  The context module for Admin Settings.
  """

  # TODO: this can be split into a context for each kind of setting

  alias Skoller.Repo
  alias Skoller.Settings.Setting
  alias Skoller.MapErrors

  import Ecto.Query

  @auto_upd_topic "AutoUpdate"
  @min_ver_topic "MinVersions"
  @syllabus_overload "SyllabusOverload"
  @notification_topic "Notification"

  @doc """
  Gets the current auto update settings from admin_settings.

  Returns `[Skoller.Settings.Setting]` or `[]`
  """
  def get_auto_update_settings(),
    do: get_settings_by_topic(@auto_upd_topic)

  @doc """
  Gets the current minimum version settings from admin_settings.

  Returns `[Skoller.Settings.Setting]` or `[]`
  """
  def get_min_ver_settings(),
    do: get_settings_by_topic(@min_ver_topic)

  @doc """
  Gets the current syllabus overload settings from admin_settings.

  Returns `Skoller.Settings.Setting` or `nil`
  """
  def get_syllabus_overload_setting(),
    do: get_settings_by_topic(@syllabus_overload) |> List.first

  @doc """
  Gets the current notification settings from admin_settings.

  Returns `[Skoller.Settings.Setting]` or `[]`
  """
  def get_notification_settings(),
    do: get_settings_by_topic(@notification_topic)

  defp get_settings_by_topic(topic) do
    from(s in Setting)
    |> where([s], s.topic == ^topic)
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
    |> Ecto.Multi.run(:settings, fn _, changes -> multi_update_settings(settings, changes) end)
    |> Repo.transaction()
  end

  def update_setting(%{"name" => name, "value" => value}) do
    get_setting_by_name!(name)
    |> Setting.changeset_update(%{value: value |> to_string()})
    |> Repo.update()
  end

  defp multi_update_settings(settings, _) do
    status = settings |> Enum.map(&update_setting/1)
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
end
