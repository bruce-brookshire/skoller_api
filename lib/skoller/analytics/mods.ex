defmodule Skoller.Analytics.Mods do
  @moduledoc """
  A context module for running analytics on mods.
  """

  alias Skoller.Mods.Type, as: ModType
  alias Skoller.Mods.Mod
  alias Skoller.Mods.Action
  alias Skoller.Assignments.Assignment
  alias Skoller.Classes.Schools
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Builds a map for each mod type that has the following keys:
   * type - the name of the mod type
   * count - the count of the mods 
   * count_private - the count of private mods
   * manual_copies - the count of manually copied actions
   * manual_dismiss - the count of manually dismissed actions
   * auto_updates - the count of auto updated mods
   * percent_mods - the ratio of mods for this type over the total amount of mods.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def mod_analytics_summary_by_type(dates, params) do
    mod_count = get_mod_count(dates, params)

    ModType 
    |> Repo.all()
    |> Enum.map(&build_mod_type_map(&1, dates, params, mod_count))
  end

  defp build_mod_type_map(type, dates, params, mod_count) do
    mod_type_count = get_mod_type_count(type, dates, params)

    Map.new()
    |> Map.put(:type, type.name)
    |> Map.put(:count, mod_type_count)
    |> Map.put(:count_private, get_private_mod_count(type, dates, params))
    |> Map.put(:manual_copies, get_manual_copies(type, dates, params))
    |> Map.put(:manual_dismiss, get_manual_dismisses(type, dates, params))
    |> Map.put(:auto_updates, get_auto_updates_count(type, dates, params))
    |> Map.put(:percent_mods, calc_mod_percent(mod_count, mod_type_count))
  end

  defp calc_mod_percent(0, _type_count), do: 0
  defp calc_mod_percent(count, type_count), do: (type_count / count) * 100

  defp get_manual_copies(type, dates, params) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, act.assignment_modification_id == m.id)
    |> join(:inner, [m, act], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, act, a], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == a.class_id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == false)
    |> where([m, act], act.is_manual == true and act.is_accepted == true)
    |> where([m, act], fragment("?::date", act.inserted_at) >= ^dates.date_start and fragment("?::date", act.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp get_manual_dismisses(type, dates, params) do
    from(m in Mod)
    |> join(:inner, [m], act in Action, act.assignment_modification_id == m.id)
    |> join(:inner, [m, act], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, act, a], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == a.class_id)
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == false)
    |> where([m, act], act.is_manual == true and act.is_accepted == false)
    |> where([m, act], fragment("?::date", act.inserted_at) >= ^dates.date_start and fragment("?::date", act.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  defp get_mod_count(dates, params) do
    from(m in mods_query(dates, params))
    |> Repo.aggregate(:count, :id)
  end

  defp get_mod_type_count(type, dates, params) do
    from(m in mods_query(dates, params))
    |> where([m], m.assignment_mod_type_id == ^type.id)
    |> Repo.aggregate(:count, :id)
  end

  defp get_auto_updates_count(type, dates, params) do
    from(m in mods_query(dates, params))
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_auto_update == true)
    |> Repo.aggregate(:count, :id)
  end

  defp get_private_mod_count(type, dates, params) do
    from(m in mods_query(dates, params))
    |> where([m], m.assignment_mod_type_id == ^type.id and m.is_private == true)
    |> Repo.aggregate(:count, :id)
  end

  defp mods_query(dates, params) do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, a.id == m.assignment_id)
    |> join(:inner, [m, a], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == a.class_id)
    |> where([m], fragment("?::date", m.inserted_at) >= ^dates.date_start and fragment("?::date", m.inserted_at) <= ^dates.date_end)
  end
end