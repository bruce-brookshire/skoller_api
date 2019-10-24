defmodule Skoller.CustomSignups do
  @moduledoc """
  Context module for custom signups.
  """

  alias Skoller.CustomSignups.Link
  alias Skoller.CustomSignups.Signup
  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.StudentPoints.StudentPoint

  import Ecto.Query

  @user_referral_point_id 2

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
    first_deg = get_links_first_degree()
    sec_deg = get_links_second_degree()

    Map.merge(
      first_deg,
      sec_deg,
      fn _, x1, x2 -> %{link: x1.link, signup_count: x1.signup_count + x2.signup_count} end
    )
    |> IO.inspect()
    |> Map.values()
    |> IO.inspect()
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
    link =
      link
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

  def link_for_student_id(student_id) do
    from(s in Signup)
    |> join(:inner, [s], l in Link, on: s.custom_signup_link_id == l.id)
    |> where([s, l], s.student_id == ^student_id)
    |> select([s, l], l)
    |> Repo.one()
  end

  defp is_active(%{start: start_date, end: end_date})
       when not is_nil(start_date) and not is_nil(end_date) do
    is_active(%{start: start_date}) and is_active(%{end: end_date})
  end

  defp is_active(%{end: end_date}) when not is_nil(end_date) do
    case DateTime.compare(DateTime.utc_now(), end_date) do
      :lt -> true
      _ -> false
    end
  end

  defp is_active(%{start: start_date}) when not is_nil(start_date) do
    case DateTime.compare(DateTime.utc_now(), start_date) do
      :gt -> true
      _ -> false
    end
  end

  defp is_active(_link), do: true

  # Gets the count of signups per link.
  defp get_links_first_degree() do
    from(l in Link)
    |> join(:left, [l], s in Signup, on: s.custom_signup_link_id == l.id)
    |> group_by([l], l.id)
    |> select([l, s], %{link: l, signup_count: count(s.student_id)})
    |> Repo.all()
    |> Enum.reduce(%{}, fn elem, acc ->
      Map.put(acc, elem.link.id, elem)
    end)
    |> IO.inspect()
  end

  defp get_links_second_degree() do
    from(p in StudentPoint)
    |> join(:inner, [p], s in Signup, on: s.student_id == p.student_id)
    |> join(:inner, [p, s, l], l in Link, on: l.id == s.custom_signup_link_id)
    |> where([p, s, l], not( is_nil(p.link_consumer_student_id)) and p.student_point_type_id == @user_referral_point_id)
    |> select([p, s, l], %{
      link: l,
      link_consumer_student_id: p.link_consumer_student_id,
      inserted_at: p.inserted_at
    })
    |> Repo.all()
    |> Enum.reduce(%{}, fn %{link_consumer_student_id: s_id} = elem, acc ->
      new_elem =
        acc
        |> Map.get(s_id)
        |> compare_and_select(elem)

      acc |> Map.put(s_id, new_elem)
    end)
    |> Enum.reduce(%{}, fn {_, %{link: %{id: id} = link}}, acc ->
      if Map.has_key?(acc, id) do
        cur_count = acc[id].signup_count
        %{acc | id => %{link: link, signup_count: cur_count + 1}}
      else
        Map.put(acc, id, %{link: link, signup_count: 1})
      end
    end)
  end

  defp compare_and_select(nil, new), do: new

  defp compare_and_select(
         %{inserted_at: c_date, link_consumer_student_id: c_id} = current,
         %{inserted_at: n_date, link_consumer_student_id: n_id} = new
       )
       when c_id == n_id do
    case NaiveDateTime.compare(n_date, c_date) do
      :lt -> new
      _ -> current
    end
  end
end
