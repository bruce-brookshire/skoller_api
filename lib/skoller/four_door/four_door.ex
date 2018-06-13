defmodule Skoller.FourDoor do

  alias Skoller.Repo
  alias Skoller.FourDoor.FourDoorOverride
  alias Skoller.Admin.Settings
  alias SkollerWeb.Helpers.RepoHelper

  def get_four_door_by_school(school_id) do
    case get_school_override(school_id) do
      nil -> get_default_four_door()
      override ->
        override |> Map.take(get_default_four_door() |> Map.keys())
    end
  end

  def override_school_four_door(school_id, params) do
    case get_school_override(school_id) do
      nil -> insert_override(params)
      override -> update_override(override, params)
    end
  end

  def get_default_four_door() do
    Settings.get_four_door_settings()
    |> Enum.reduce(%{}, &Map.put(&2, String.to_atom(&1.name), strip_bool(&1.value)))
  end

  def delete_override(school_id) do
    school_id
    |> get_school_override!()
    |> Repo.delete()
  end

  def update_four_door_defaults(params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:settings, &update_four_door_defaults(params, &1))
    |> Repo.transaction()
  end
  defp update_four_door_defaults(params, _) do
    status = params |> Enum.map(&update_setting(&1))
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp update_setting(item) do
    settings_old = Settings.get_setting_by_name!(elem(item, 0))
    Settings.update_setting(settings_old, %{value: to_string(elem(item, 1))})
  end

  defp insert_override(params) do
    %FourDoorOverride{}
    |> FourDoorOverride.changeset(params)
    |> Repo.insert()
  end

  defp update_override(override_old, params) do
    override_old
    |> FourDoorOverride.changeset(params)
    |> Repo.update()
  end

  defp get_school_override(school_id) do
    Repo.get_by(FourDoorOverride, school_id: school_id)
  end

  defp get_school_override!(school_id) do
    Repo.get_by!(FourDoorOverride, school_id: school_id)
  end

  defp strip_bool("true") do
    true
  end
  defp strip_bool("false") do
    false
  end
end