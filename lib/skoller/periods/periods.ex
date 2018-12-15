defmodule Skoller.Periods do
  @moduledoc """
  Context module for class periods
  """

  alias Skoller.Periods.ClassPeriod
  alias Skoller.Repo
  alias Skoller.Periods.Notifications
  alias Skoller.Periods.Generator
  alias Skoller.Schools

  import Ecto.Query

  @past_status 100
  @active_status 200
  @prompt_status 300
  @future_status 400
  
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
    ClassPeriod.changeset_update(period_old, params)
    |> Repo.update()
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
    result = period
    |> Ecto.Changeset.change(%{class_period_status_id: @prompt_status})
    |> Repo.update()

    #Task.start(Notifications, :prompt_for_future_enrollment_notification, [period])
    result
  end
  def update_period_status(period, status_id) do
    period
    |> Ecto.Changeset.change(%{class_period_status_id: status_id})
    |> Repo.update()
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
    |> Repo.one!
  end

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
    get_generators()
    |> Enum.map(&create_period_from_generator(&1, school_id, year))
  end

  defp get_generators() do
    Repo.all(Generator)
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
    |> create_period([is_generator: true])
  end

  defp find_changeset_status(%Ecto.Changeset{valid?: true, changes: %{start_date: start_date, end_date: end_date}} = changeset) do
    status = find_status(start_date, end_date)
    changeset |> Ecto.Changeset.change(%{class_period_status_id: status})
  end
  defp find_changeset_status(changeset), do: changeset

  defp find_changeset_main_period(%Ecto.Changeset{valid?: true} = changeset, %{is_main_period: is_main_period}, opts) when opts != [] do
    case opts |> Keyword.get(:is_generator, false) do
      true -> changeset |> Ecto.Changeset.change(%{is_main_period: is_main_period})
      _ -> changeset
    end
  end
  defp find_changeset_main_period(%Ecto.Changeset{valid?: true} = changeset, %{"is_main_period" => is_main_period}, opts) when opts != [] do
    case opts |> Keyword.get(:admin, false) do
      true -> changeset |> Ecto.Changeset.change(%{is_main_period: is_main_period})
      _ -> changeset
    end
  end
  defp find_changeset_main_period(changeset, _params, _opts), do: changeset

  defp find_status(start_date, end_date) do
    now = DateTime.utc_now()

    case DateTime.compare(start_date, now) do
      :gt -> @future_status
      _ ->
        case DateTime.compare(end_date, now) do
          :gt -> @active_status
          _ -> @past_status
        end
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
end