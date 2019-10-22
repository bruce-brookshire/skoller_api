defmodule Skoller.Schools do
  @moduledoc """
  The Schools context.
  """

  alias Skoller.Repo
  alias Skoller.Schools.School
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Timezone
  alias Skoller.FourDoor
  alias Skoller.Schools.Timezones
  alias Skoller.Schools.EmailDomain
  alias Skoller.Periods

  import Ecto.Query

  @doc """
    Creates a `Skoller.Schools.School`
  """
  def create_school(params) do
    {:ok, timezone} = get_timezone(params)

    %School{}
    |> School.changeset_insert(params)
    |> Ecto.Changeset.change(%{timezone: timezone})
    |> Repo.insert()
    |> add_four_door()
    |> add_future_periods()
  end

  @doc """
    Gets a `Skoller.Schools.School` by id
  """
  def get_school_by_id!(id) do
    school = Repo.get!(School, id)
    {:ok, school} = add_four_door({:ok, school})
    school
  end

  @doc """
  Updates a school.

  ## Returns
  `{:ok, school}` or `{:error, changeset}`
  """
  def update_school(school_old, params) do
    {:ok, timezone} = get_timezone(params)

    changeset =
      school_old
      |> School.changeset_update(params)
      |> process_timezone_updates(school_old, timezone)

    {:ok, results} =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:school, changeset)
      |> Ecto.Multi.merge(&update_school_times(&1.school, school_old))
      |> Repo.transaction()

    {:ok, results.school}
    |> add_four_door()
  end

  @doc """
    Gets a `Skoller.Schools.School` from a `Skoller.Periods.ClassPeriod`
  """
  def get_school_from_period(class_period_id) do
    school =
      from(cp in ClassPeriod)
      |> join(:inner, [cp], s in School, on: s.id == cp.school_id)
      |> where([cp], cp.id == ^class_period_id)
      |> select([cp, s], s)
      |> Repo.one()

    {:ok, school} = add_four_door({:ok, school})
    school
  end

  @doc """
    Gets a list of `Skoller.Schools.School` with filters.

    ##Filters
      * short_name
        * Gets schools by short_name (for scripting generally).
  """
  def get_schools(%{"name" => name}) do
    {schools, occs} =
      name
      |> String.split(" ", trim: true)
      |> Enum.map(&search_schools(%{"name" => &1}))
      |> Enum.concat()
      |> Enum.reduce({%{}, %{}}, fn elem, {t_schools, t_occs} ->
        school_id = elem.id

        if Map.has_key?(t_occs, school_id) do
          {t_schools, %{t_occs | school_id => t_occs[school_id] + 1}}
        else
          {Map.put(t_schools, school_id, elem), Map.put(t_occs, school_id, 1)}
        end
      end)

    occs
    |> Map.keys()
    |> Enum.sort_by(&occs[&1])
    |> Enum.reverse()
    |> Enum.take(50)
    |> Enum.map(&schools[&1])
  end
  
  def get_schools(_), do: search_schools(%{}) |> Enum.take(50)

  defp search_schools(filters),
    do:
      from(school in School)
      |> filter(filters)
      |> Repo.all()

  @doc """
  Returns the list of school_email_domains.

  ## Examples

      iex> get_email_domains_by_school()
      [%EmailDomain{}, ...]

  """
  def get_email_domains_by_school(school_id) do
    from(e in EmailDomain)
    |> where([e], e.school_id == ^school_id)
    |> Repo.all()
  end

  @doc """
  Gets a single email_domain.

  Raises `Ecto.NoResultsError` if the Email domain does not exist.

  ## Examples

      iex> get_email_domain!(123)
      %EmailDomain{}

      iex> get_email_domain!(456)
      ** (Ecto.NoResultsError)

  """
  def get_email_domain!(id), do: Repo.get!(EmailDomain, id)

  @doc """
  Creates a email_domain.

  ## Examples

      iex> create_email_domain(%{field: value})
      {:ok, %EmailDomain{}}

      iex> create_email_domain(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_email_domain(attrs \\ %{}) do
    %EmailDomain{}
    |> EmailDomain.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a email_domain.

  ## Examples

      iex> update_email_domain(email_domain, %{field: new_value})
      {:ok, %EmailDomain{}}

      iex> update_email_domain(email_domain, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_email_domain(%EmailDomain{} = email_domain, attrs) do
    email_domain
    |> EmailDomain.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a EmailDomain.

  ## Examples

      iex> delete_email_domain(email_domain)
      {:ok, %EmailDomain{}}

      iex> delete_email_domain(email_domain)
      {:error, %Ecto.Changeset{}}

  """
  def delete_email_domain(%EmailDomain{} = email_domain) do
    Repo.delete(email_domain)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking email_domain changes.

  ## Examples

      iex> change_email_domain(email_domain)
      %Ecto.Changeset{source: %EmailDomain{}}

  """
  def change_email_domain(%EmailDomain{} = email_domain) do
    EmailDomain.changeset(email_domain, %{})
  end

  @doc """
  Gets the school from an email domain. Returns raises if there is no match.
  """
  def get_school_from_email_domain!(domain) do
    trimmed_domain = get_last_section_of_email_domain(domain)

    school_ids =
      from(d in EmailDomain, where: d.email_domain == ^trimmed_domain, select: d.school_id)
      |> Repo.all()

    schools = from(s in School, where: s.id in ^school_ids) |> Repo.all()
    schools
  end

  defp add_future_periods({:ok, school} = result) do
    # Hard coded because this should not be the way this is done.
    # 2019 will be the default only for now.
    # TODO: Figure out the long term solution based on success or failure of new
    # onboarding.
    Periods.generate_periods_for_year_for_school(school.id, 2019)
    result
  end

  defp add_future_periods(result), do: result

  defp get_last_section_of_email_domain(domain) do
    domain
    |> String.split(".", trim: true)
    |> get_last_two_elements()
    |> Enum.intersperse(".")
    |> List.to_string()
  end

  defp get_last_two_elements(list) do
    len = length(list)
    list |> Enum.slice((len - 2)..(len - 1))
  end

  defp update_school_times(school, %{timezone: nil}) do
    Timezones.process_timezone_change("Etc/UTC", school)
  end

  defp update_school_times(school, %{timezone: old_timezone}) do
    case old_timezone == school.timezone do
      true ->
        Ecto.Multi.new()

      false ->
        Timezones.process_timezone_change(old_timezone, school)
    end
  end

  defp process_timezone_updates(changeset, _school, nil), do: changeset

  defp process_timezone_updates(changeset, %{timezone: nil}, new_timezone),
    do: changeset |> Ecto.Changeset.change(%{timezone: new_timezone})

  defp process_timezone_updates(changeset, %{timezone: old_timezone}, new_timezone) do
    case old_timezone == new_timezone do
      true ->
        changeset

      false ->
        changeset |> Ecto.Changeset.change(%{timezone: new_timezone})
    end
  end

  defp process_timezone_updates(changeset, _old_school, _timezone), do: changeset

  # There are two of these, one for string maps and one for atom maps.
  defp get_timezone(%{adr_locality: loc, adr_country: country, adr_region: region}) do
    call_timezone(loc, country, region)
  end

  defp get_timezone(%{"adr_locality" => loc, "adr_country" => country, "adr_region" => region}) do
    call_timezone(loc, country, region)
  end

  defp get_timezone(_params), do: {:ok, nil}

  defp call_timezone(loc, country, region) do
    Timezone.get_timezone(loc, country, region)
  end

  defp add_four_door({:ok, school}) do
    {:ok, with_four_door(school)}
  end

  defp add_four_door({:error, _school} = response), do: response

  def with_four_door(%School{} = school) do
    FourDoor.get_four_door_by_school(school.id) |> Map.merge(school)
  end

  def with_four_door(schools) when is_list(schools) do
    for school <- schools, into: [], do: with_four_door(school)
  end

  defp filter(query, params) do
    query
    |> short_name_filter(params)
    |> name_filter(params)
  end

  defp name_filter(query, %{"name" => name}) do
    name_filter = "%" <> name <> "%"

    query
    |> where([school], ilike(school.name, ^name_filter))
    |> limit(50)
  end

  defp name_filter(query, _params), do: query

  defp short_name_filter(query, %{"short_name" => short_name}) do
    query
    |> where([school], school.short_name == ^short_name)
  end

  defp short_name_filter(query, _params), do: query
end
