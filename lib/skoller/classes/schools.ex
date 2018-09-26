defmodule Skoller.Classes.Schools do
  @moduledoc """
  
  A context module for class schools

  """

  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Professors.Professor
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Get all classes for a school, with professors and class periods.

  ## Filters
   * `%{"professor_name" => prof_first_or_last}`, filters professor first or last name with a contains search
   * `%{"professor_id" => professor_id}`, filters professor id
   * `%{"class_name" => class_name}`, filters class name
   * `%{"or" => "true"}`, "or's" the filters instead of making them exclusive.

  ## Returns
  `[%{class: Skoller.Classes.Class, professor: Skoller.Professors.Professor, class_period: Skoller.Periods.ClassPeriod}]`
  or `[]`

  """
  def get_classes_by_school(school_id, filters \\ nil) do
    #TODO: Filter ClassPeriod
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id and period.is_hidden == false)
    |> join(:left, [class], prof in Professor, class.professor_id == prof.id)
    |> where([class, period], period.school_id == ^school_id)
    |> where([class, period, prof], ^filter(filters))
    |> select([class, period, prof], %{class: class, professor: prof, class_period: period})
    |> order_by([class], desc: class.inserted_at)
    |> limit(50)
    |> Repo.all()
  end

  @doc """
  Gets all class_id and school_id.

  ## Params
  `%{"school_id" => id}`, gets all classes in in school
  """
  def get_school_from_class_subquery(_params \\ %{})
  def get_school_from_class_subquery(%{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([c, p], p.school_id == ^school_id)
    |> select([c, p], %{class_id: c.id, school_id: p.school_id})
  end
  def get_school_from_class_subquery(_params) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> select([c, p], %{class_id: c.id, school_id: p.school_id})
  end

  defp filter(nil), do: true
  defp filter(%{} = params) do
    dynamic = params["or"] != "true"

    dynamic
    |> prof_filter(params)
    |> prof_id_filter(params)
    |> name_filter(params)
  end

  defp prof_filter(dynamic, %{"professor_name" => filter, "or" => "true"}) do
    prof_filter = filter <> "%"
    dynamic([class, period, prof], ilike(prof.name_last, ^prof_filter) or ilike(prof.name_first, ^prof_filter) or ^dynamic)
  end
  defp prof_filter(dynamic, %{"professor_name" => filter}) do
    prof_filter = filter <> "%"
    dynamic([class, period, prof], (ilike(prof.name_last, ^prof_filter) or ilike(prof.name_first, ^prof_filter)) and ^dynamic)
  end
  defp prof_filter(dynamic, _), do: dynamic

  defp prof_id_filter(dynamic, %{"professor_id" => filter, "or" => "true"}) do
    dynamic([class, period, prof], prof.id == ^filter or ^dynamic)
  end
  defp prof_id_filter(dynamic, %{"professor_id" => filter}) do
    dynamic([class, period, prof], prof.id == ^filter and ^dynamic)
  end
  defp prof_id_filter(dynamic, _), do: dynamic

  defp name_filter(dynamic, %{"class_name" => filter, "or" => "true"}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) or ^dynamic)
  end
  defp name_filter(dynamic, %{"class_name" => filter}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) and ^dynamic)
  end
  defp name_filter(dynamic, _), do: dynamic
end