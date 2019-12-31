defmodule Skoller.Professors do
  @moduledoc """
  Context module for professors
  """

  alias Skoller.Repo
  alias Skoller.Professors.Professor
  alias Skoller.Changeset

  import Ecto.Query

  @student_role 100

  @doc """
  Creates a professor

  ## Returns
  `{:ok, Skoller.Professors.Professor}` or `{:error, Ecto.Changeset}`
  """
  def create_professor(params) do
    Professor.changeset_insert(%Professor{}, params)
    |> Repo.insert()
  end

  @doc """
  Updates a professor

  ## Returns
  `{:ok, Skoller.Professors.Professor}` or `{:error, Ecto.Changeset}`
  """
  def update_professor(professor_old, params, user \\ nil) do
    Professor.changeset_update(professor_old, params)
    |> clean_changes_for_students(professor_old, user)
    |> Repo.update()
  end

  @doc """
  Gets a professor by id

  ## Returns
  `Skoller.Professors.Professor` or `Ecto.NoResultsError`
  """
  def get_professor_by_id!(id) do
    Repo.get!(Professor, id)
  end

  @doc """
  Gets professors by school

  ## Params
   * %{"professor_name" => professor_name}, filters on professor name.

  ## Returns
  `[Skoller.Professors.Professor]` or `[]`
  """
  def get_professors(school_id, params \\ %{})
  # def get_professors(school_id, %{"professor_name" => name}) do
  #   {profs, occs} =
  #     name
  #     |> String.split(" ", trim: true)
  #     |> Enum.map(&search_professors(school_id, %{"professor_name" => &1}))
  #     |> Enum.concat()
  #     |> Enum.reduce({%{}, %{}}, fn elem, {t_profs, t_occs} ->
  #       prof_id = elem.id

  #       if Map.has_key?(t_occs, prof_id) do
  #         {t_profs, %{t_occs | prof_id => t_occs[prof_id] + 1}}
  #       else
  #         {Map.put(t_profs, prof_id, elem), Map.put(t_occs, prof_id, 1)}
  #       end
  #     end)

  #   occs
  #   |> Map.keys()
  #   |> Enum.sort_by(&occs[&1])
  #   |> Enum.reverse()
  #   |> Enum.take(50)
  #   |> Enum.map(&profs[&1])
  # end

  def get_professors(school_id, params), do: search_professors(school_id, params) |> Enum.take(50)

  @doc """
  Gets professor by name and school

  ## Returns
  `Skoller.Professors.Professor` or `nil`
  """
  def get_professor_by_name(name_first, name_last, school_id) do
    name_first = name_first |> String.trim()
    name_last = name_last |> String.trim()

    from(p in Professor)
    |> where(
      [p],
      p.name_first == ^name_first and p.name_last == ^name_last and p.school_id == ^school_id
    )
    |> limit(1)
    |> Repo.one()
  end

  defp search_professors(school_id, params) do
    from(p in Professor)
    |> where([p], p.school_id == ^school_id)
    |> filters(params)
    |> Repo.all()
  end

  defp clean_changes_for_students(changeset, _professor_old, nil), do: changeset

  defp clean_changes_for_students(%{changes: current_changes} = changeset, professor_old, user)
       when current_changes != %{} do
    case user.roles |> Enum.any?(&(&1.id == @student_role)) do
      true ->
        new_changes = changeset |> Changeset.get_new_changes(professor_old)
        non_allowed_changes = new_changes |> get_non_new_changes(current_changes)

        changeset
        |> Changeset.delete_changes(non_allowed_changes)
        |> Ecto.Changeset.change(new_changes)

      false ->
        changeset
    end
  end

  defp clean_changes_for_students(changeset, _professor_old, _user), do: changeset

  defp get_non_new_changes(new_changes, current_changes) do
    current_changes
    |> Map.to_list()
    |> Enum.filter(&(!Map.has_key?(new_changes, elem(&1, 0))))
  end

  defp filters(query, params) do
    query
    |> name_filter(params)
  end

  defp name_filter(query, %{"professor_name" => professor_name}) do
    prof_filter = "%" <> professor_name <> "%"

    query
    |> where([p], ilike(p.name_first, ^prof_filter) or ilike(p.name_last, ^prof_filter))
  end

  defp name_filter(query, _params), do: query
end
