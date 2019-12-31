defmodule Skoller.Periods do
  @moduledoc """
  Context module for class periods
  """

  alias Skoller.Periods.ClassPeriod
  alias Skoller.Repo
  alias Skoller.Periods.Generator
  alias Skoller.Schools
  alias Skoller.Classes.Class
  alias Skoller.Professors.Professor
  alias Skoller.EnrolledStudents

  import Ecto.Query

  @past_status 100
  @active_status 200
  @prompt_status 300
  @future_status 400

  def past_status_id(), do: @past_status
  def active_status_id(), do: @active_status
  def prompt_status_id(), do: @prompt_status
  def future_status_id(), do: @future_status

  @doc """
  Gets class periods by school.

  ## Params
   * `%{"name" => period_name}`, filters period name

  ## Returns
  `[Skoller.Periods.ClassPeriod]` or `[]`
  """
  def get_periods_by_school_id(school_id, params \\ %{}) do
    from(period in ClassPeriod)
    |> where([period], period.school_id == ^school_id)
    |> where([period], period.is_hidden == false)
    |> filter(params)
    |> Repo.all()
  end

  def get_classes_by_period_id(period_id, params \\ %{})

  # def get_classes_by_period_id(period_id, %{"class_name" => name}) do
  #   {classes, occs} =
  #     name
  #     |> String.split(" ", trim: true)
  #     |> Enum.map(&search_classes_by_period_id(period_id, %{"class_name" => &1}))
  #     |> Enum.concat()
  #     |> Enum.reduce({%{}, %{}}, fn elem, {t_classes, t_occs} ->
  #       class_id = elem.class.id

  #       if Map.has_key?(t_occs, class_id) do
  #         {t_classes, %{t_occs | class_id => t_occs[class_id] + 1}}
  #       else
  #         {Map.put(t_classes, class_id, elem), Map.put(t_occs, class_id, 1)}
  #       end
  #     end)

  #   occs
  #   |> Map.keys()
  #   |> Enum.sort_by(&{classes[&1].enrollment, occs[&1]})
  #   |> Enum.reverse()
  #   |> Enum.take(50)
  #   |> Enum.map(&classes[&1])
  # end

  def get_classes_by_period_id(period_id, params),
    do: search_classes_by_period_id(period_id, params)

  defp search_classes_by_period_id(period_id, filters),
    do:
      from(class in Class)
      |> join(:inner, [class], period in ClassPeriod,
        on:
          period.id == ^period_id and class.class_period_id == period.id and
            period.is_hidden == false
      )
      |> join(:left, [class], prof in Professor, on: class.professor_id == prof.id)
      |> where([class, period, prof], ^class_filter(filters))
      |> select([class, period, prof], %{class: class, professor: prof, class_period: period})
      |> order_by([class], desc: class.inserted_at)
      |> limit(50)
      |> Repo.all()
      |> Enum.map(fn class ->
        Map.put(class, :enrollment, EnrolledStudents.get_enrollment_by_class_id(class.class.id))
      end)

  @doc """
  Creates a period

  ## Returns
  `{:ok, Skoller.Periods.ClassPeriod}` or `{:error, Ecto.Changeset}`
  """
  def create_period(params, opts \\ []) do
    ClassPeriod.changeset_insert(%ClassPeriod{}, params)
    |> find_changeset_status()
    |> find_changeset_main_period(params, opts)
    |> Repo.insert()
  end

  @doc """
  Updates a period

  ## Returns
  `{:ok, Skoller.Periods.ClassPeriod}` or `{:error, Ecto.Changeset}`
  """
  def update_period(period_old, params) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:class_period, ClassPeriod.changeset_update(period_old, params))
      |> Ecto.Multi.run(:period, fn _, %{class_period: class_period} ->
        reset_status(class_period)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{period: period}} ->
        {:ok, period}

      {:error, _, failed_result, _} ->
        {:error, failed_result}

      _ ->
        {:error, %{}}
    end
  end

  @doc """
  Gets a period by id. Raises if not found.
  """
  def get_period!(id) do
    Repo.get!(ClassPeriod, id)
  end

  @doc """
  Updates a period's status.

  Sends a notification when a period changes to prompt status for
  the first time.

  ## Returns
  `{:ok, Skoller.Periods.ClassPeriod}` or `{:error, Ecto.Changeset}`
  """
  def update_period_status(period, @prompt_status) do
    result =
      period
      |> update_period_status_changeset(@prompt_status)
      |> Repo.update()

    # Task.start(Notifications, :prompt_for_future_enrollment_notification, [period])
    result
  end

  def update_period_status(period, status_id) do
    period
    |> update_period_status_changeset(status_id)
    |> Repo.update()
  end

  def update_period_status_changeset(period, status_id) do
    Ecto.Changeset.change(period, %{class_period_status_id: status_id})
  end

  @doc """
  Gets the closest "Future" main period for the school
  """
  def get_next_period_for_school(school_id) do
    from(c in ClassPeriod)
    |> where([c], c.is_main_period == true and c.school_id == ^school_id)
    |> where([c], c.class_period_status_id == @future_status)
    |> order_by([c], asc: c.start_date)
    |> limit(1)
    |> Repo.one!()
  end

  @doc """

  """
  def duplicate_previous_periods_for_all_schools_for_year(year) do
    start_date_test = get_datetime_string("#{year - 1}-01-01 00:00:00Z")
    end_date_test = get_datetime_string("#{year - 1}-12-31 00:00:00Z")

    from(c in ClassPeriod)
    |> where(
      [c],
      c.start_date >= ^start_date_test and c.start_date < ^end_date_test
    )
    |> Repo.all()
    |> Enum.map(&adjust_period_to_new_year(&1, year))
    |> Enum.filter(&(&1 != nil && &1.valid?))
    |> Enum.map(&Repo.insert/1)
    |> Enum.filter(&(Kernel.elem(&1, 0) != :ok))
  end

  defp adjust_period_to_new_year(
         %ClassPeriod{name: name, start_date: start_date, end_date: end_date} = period,
         year
       ) do
    start_date_str = start_date |> DateTime.to_string()
    end_date_str = end_date |> DateTime.to_string()

    utc_now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    updated_values = %{
      name: Regex.replace(~r/#{year - 1}/, name, "#{year}"),
      start_date: convert_datetime(year, start_date_str),
      end_date: convert_datetime(year, end_date_str),
      inserted_at: utc_now,
      updated_at: utc_now,
      class_period_status_id: @future_status
    }

    if updated_values.name == name do
      nil
    else
      Map.merge(
        %ClassPeriod{},
        Map.take(period, [
          :school_id,
          :is_main_period
        ])
      )
      |> ClassPeriod.changeset_insert(updated_values)
    end
  end

  defp get_datetime_string(datetime),
    do:
      DateTime.from_iso8601(datetime)
      |> Kernel.elem(1)
      |> DateTime.to_string()

  defp convert_datetime(year, datetime_str),
    do:
      Regex.replace(~r/#{year - 1}/, datetime_str, "#{year}")
      |> DateTime.from_iso8601()
      |> Kernel.elem(1)

  @doc """
  Generates a year's worth of periods for all schools.
  """
  def generate_periods_for_all_schools_for_year(year) do
    Schools.get_schools()
    |> Enum.each(&generate_periods_for_year_for_school(&1.id, year))
  end

  @doc """
  Generates a year's worth of periods for `school_id`.
  """
  def generate_periods_for_year_for_school(school_id, year) do
    Generator
    |> Repo.all()
    |> Enum.map(&create_period_from_generator(&1, school_id, year))
  end

  defp create_period_from_generator(generator, school_id, year) do
    {:ok, start_date} = Date.new(year, generator.start_month, generator.start_day)
    {:ok, end_date} = Date.new(year, generator.end_month, generator.end_day)

    school = Schools.get_school_by_id!(school_id)

    start_date = start_date |> Timex.to_datetime(school.timezone) |> Timex.to_datetime()
    end_date = end_date |> Timex.to_datetime(school.timezone) |> Timex.to_datetime()

    Map.new()
    |> Map.put(:school_id, school_id)
    |> Map.put(:start_date, start_date)
    |> Map.put(:end_date, end_date)
    |> Map.put(:name, generator.name_prefix <> " " <> to_string(year))
    |> Map.put(:is_main_period, generator.is_main_period)
    |> create_period(is_generator: true)
  end

  defp find_changeset_status(
         %Ecto.Changeset{valid?: true, changes: %{start_date: start_date, end_date: end_date}} =
           changeset
       ) do
    status = find_status(start_date, end_date)
    changeset |> Ecto.Changeset.change(%{class_period_status_id: status})
  end

  defp find_changeset_status(changeset), do: changeset

  defp find_changeset_main_period(
         %Ecto.Changeset{valid?: true} = changeset,
         %{is_main_period: is_main_period},
         opts
       )
       when opts != [] do
    case opts |> Keyword.get(:is_generator, false) do
      true -> changeset |> Ecto.Changeset.change(%{is_main_period: is_main_period})
      _ -> changeset
    end
  end

  defp find_changeset_main_period(
         %Ecto.Changeset{valid?: true} = changeset,
         %{"is_main_period" => is_main_period},
         opts
       )
       when opts != [] do
    case opts |> Keyword.get(:admin, false) do
      true -> changeset |> Ecto.Changeset.change(%{is_main_period: is_main_period})
      _ -> changeset
    end
  end

  defp find_changeset_main_period(changeset, _params, _opts), do: changeset

  defp find_status(start_date, end_date) do
    now = DateTime.utc_now()

    case DateTime.compare(start_date, now) do
      :gt ->
        @future_status

      _ ->
        case DateTime.compare(end_date, now) do
          :gt -> @active_status
          _ -> @past_status
        end
    end
  end

  def reset_status(class_period) do
    status_id = find_status(class_period.start_date, class_period.end_date)

    cond do
      # If status is unchanged, do not update
      status_id == class_period.class_period_status_id ->
        {:ok, class_period}

      # If we've entered prompt already, do not reset to active
      status_id == @active_status && class_period.class_period_status_id == @prompt_status ->
        {:ok, class_period}

      # Update status
      true ->
        update_period_status(class_period, status_id)
    end
  end

  defp filter(query, params) do
    query
    |> filter_name(params)
  end

  defp filter_name(query, %{"name" => filter}) do
    name_filter = filter <> "%"
    query |> where([period], ilike(period.name, ^name_filter))
  end

  defp filter_name(query, _params), do: query

  defp class_filter(nil), do: true

  defp class_filter(%{} = params) do
    dynamic = params["or"] != "true"

    dynamic
    |> prof_class_filter(params)
    |> prof_id_class_filter(params)
    |> name_class_filter(params)
  end

  defp prof_class_filter(dynamic, %{"professor_name" => class_filter, "or" => "true"}) do
    prof_class_filter = class_filter <> "%"

    dynamic(
      [class, period, prof],
      ilike(prof.name_last, ^prof_class_filter) or ilike(prof.name_first, ^prof_class_filter) or
        ^dynamic
    )
  end

  defp prof_class_filter(dynamic, %{"professor_name" => class_filter}) do
    prof_class_filter = class_filter <> "%"

    dynamic(
      [class, period, prof],
      (ilike(prof.name_last, ^prof_class_filter) or ilike(prof.name_first, ^prof_class_filter)) and
        ^dynamic
    )
  end

  defp prof_class_filter(dynamic, _), do: dynamic

  defp prof_id_class_filter(dynamic, %{"professor_id" => class_filter, "or" => "true"}) do
    dynamic([class, period, prof], prof.id == ^class_filter or ^dynamic)
  end

  defp prof_id_class_filter(dynamic, %{"professor_id" => class_filter}) do
    dynamic([class, period, prof], prof.id == ^class_filter and ^dynamic)
  end

  defp prof_id_class_filter(dynamic, _), do: dynamic

  defp name_class_filter(dynamic, %{"class_name" => class_filter, "or" => "true"}) do
    name_class_filter = "%" <> class_filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_class_filter) or ^dynamic)
  end

  defp name_class_filter(dynamic, %{"class_name" => class_filter}) do
    name_class_filter = "%" <> class_filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_class_filter) and ^dynamic)
  end

  defp name_class_filter(dynamic, _), do: dynamic
end
