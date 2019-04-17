defmodule Skoller.CustomSignups do
  @moduledoc """
  Context module for custom signups.
  """

  alias Skoller.CustomSignups.Link
  alias Skoller.CustomSignups.Signup
  alias Skoller.Repo
  alias Skoller.Students.Student

  import Ecto.Query

  @doc """
  Creates a new custom link

  ## Returns
  `{:ok, Skoller.CustomSignups.Link}` or `{:error, Ecto.Changeset}`
  """
  def create_link(params) do
    %Link{}
    |> Link.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Gets links with signup count.

  ## Returns
  `[%{link: Skoller.CustomSignups.Link, signup_count: Integer}]` or `[]`
  """
  def get_links() do
    from(l in Link)
    |> join(:inner, [l], c in subquery(get_link_student_count_subquery()), on: c.link_id == l.id)
    |> select([l, c], %{link: l, signup_count: c.count})
    |> Repo.all()
  end

  @doc """
  Gets a link by id.

  ## Returns
  `Skoller.CustomSignups.Link` or raises if not found
  """
  def get_link_by_id!(id) do
    Repo.get!(Link, id)
  end

  @doc """
  Gets a link object by the custom link

  ## Returns
  `Skoller.CustomSignups.Link` or `nil`
  """
  def get_link_by_link(link) do
    link = link
    |> String.trim()
    |> String.downcase()
    Repo.get_by(Link, link: link)
  end

  @doc """
  Updates a custom link.

  ## Returns
  `{:ok, Skoller.CustomSignups.Link}` or `{:error, Ecto.Changeset}`
  """
  def update_link(link_old, params) do
    link_old
    |> Link.changeset_update(params)
    |> Repo.update()
  end

  @doc """
  Attributes a signup to a custom link

  ## Returns
  `{:ok, Skoller.CustomSignups.Signup}` or `{:error, Ecto.Changeset}`
  """
  def track_signup(student_id, link_id) do
    link = get_link_by_id!(link_id)
    case link |> is_active do
      true -> 
        Repo.insert(%Signup{custom_signup_link_id: link_id, student_id: student_id})
      false ->
        {:ok, nil}
    end
  end

  def signup_organization_name_for_student_id(student_id) do
    from(s in Signup)
      |> join(:inner, [s], l in Link, on: s.custom_signup_link_id == l.id)
      |> where([s, l], s.student_id == ^student_id)
      |> select([s, l], l.name)
      |> Repo.one()
  end

  defp is_active(%{start: start_date, end: end_date}) when (not is_nil(start_date)) and (not is_nil(end_date)) do
    is_active(%{start: start_date}) and is_active(%{end: end_date})
  end
  defp is_active(%{end: end_date}) when not is_nil(end_date) do
    case DateTime.compare(DateTime.utc_now, end_date) do
      :lt -> true
      _ -> false
    end
  end
  defp is_active(%{start: start_date}) when not is_nil(start_date) do
    case DateTime.compare(DateTime.utc_now, start_date) do
      :gt -> true
      _ -> false
    end
  end
  defp is_active(_link), do: true

  # Gets the count of signups per link.
  defp get_link_student_count_subquery() do
    from(l in Link)
    |> join(:left, [l], s in Signup, on: s.custom_signup_link_id == l.id)
    |> join(:left, [l, s], stu in Student, on: stu.id == s.student_id)
    |> group_by([l], l.id)
    |> select([l, s, stu], %{link_id: l.id, count: count(stu.id)})
  end
end