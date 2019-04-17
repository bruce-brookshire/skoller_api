defmodule Skoller.FourDoor do
  @moduledoc """
  Context module for Project Four Door
  """

  alias Skoller.Repo
  alias Skoller.FourDoor.FourDoorOverride
  alias Skoller.Settings
  alias Skoller.Schools.School

  import Ecto.Query

  @doc """
  Gets the four door status for a school.

  ## Returns
  `%{setting_name: Boolean}` where setting_name is the four door setting.
  There are as many map keys as there are settings (whatever keys exist in `get_default_four_door/0`)
  """
  def get_four_door_by_school(school_id) do
    case get_school_override(school_id) do
      nil -> get_default_four_door()
      override ->
        override |> Map.take(get_default_four_door() |> Map.keys())
    end
  end

  @doc """
  Gets schools with four door overrides

  ## Returns
  `[Skoller.Schools.School]` or `[]`
  """
  def get_four_door_overrides() do
    from(s in School)
    |> join(:inner, [s], fdo in FourDoorOverride, on: s.id == fdo.school_id)
    |> Repo.all()
  end

  @doc """
  Overrides the school's current four door settings.

  ## Returns
  `{:ok, Skoller.FourDoor.FourDoorOverride}` or `{:error, Ecto.Changeset}`
  """
  def override_school_four_door(school_id, params) do
    case get_school_override(school_id) do
      nil -> insert_override(params)
      override -> update_override(override, params)
    end
  end

  @doc """
  Gets the current default four door settings as a `Map`

  ## Keys
   * is_diy_enabled
   * is_diy_preferred
   * is_auto_syllabus

  ## Returns
  a `Map` of name, Boolean pairs
  """
  def get_default_four_door() do
    Settings.get_four_door_settings()
    |> Enum.reduce(%{}, &Map.put(&2, String.to_atom(&1.name), strip_bool(&1.value)))
  end

  @doc """
  Deletes any school overrides and reverts the class to the default four door status

  ## Returns
  `{:ok, Skoller.FourDoor.FourDoorOverride}` or `Ecto.NoResultsError`
  """
  def delete_override(school_id) do
    school_id
    |> get_school_override!()
    |> Repo.delete()
  end

  @doc """
  Updates the four door defaults

  ## Returns
  `{:ok, %{settings: {:ok, [Skoller.Settings.Setting]}}}` or `{:error, _, _, _}`
  """
  def update_four_door_defaults(params) do
    Settings.update_settings(params)
  end

  defp insert_override(params) do
    map = params |> generate_map_from_settings_list()
    %FourDoorOverride{}
    |> FourDoorOverride.changeset(map)
    |> Repo.insert()
  end

  defp update_override(override_old, params) do
    map = params |> generate_map_from_settings_list()
    override_old
    |> FourDoorOverride.changeset(map)
    |> Repo.update()
  end

  defp get_school_override(school_id) do
    Repo.get_by(FourDoorOverride, school_id: school_id)
  end

  defp get_school_override!(school_id) do
    Repo.get_by!(FourDoorOverride, school_id: school_id)
  end

  defp generate_map_from_settings_list(list) do
    list |> List.foldl(Map.new, & &2 |> Map.put(&1["name"], &1["value"]))
  end

  defp strip_bool("true") do
    true
  end
  defp strip_bool("false") do
    false
  end
end