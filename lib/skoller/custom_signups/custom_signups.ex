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
    |> join(:inner, [l], c in subquery(get_link_student_count_subquery()), c.link_id == l.id)
    |> select([l, c], %{link: l, signup_count: c.count})
    |> Repo.all()
  end

  @doc """
  Gets a link by id.

  ## Returns
  `Skoller.CustomSignups.Link` or `nil`
  """
  def get_link_by_id(id) do
    Repo.get(Link, id)
  end

  @doc """
  Gets a link object by the custom link

  ## Returns
  `Skoller.CustomSignups.Link` or `nil`
  """
  def get_link_by_link(link) do
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
    Repo.insert(%Signup{custom_signup_link_id: link_id, student_id: student_id})
  end

  # Gets the count of signups per link.
  defp get_link_student_count_subquery() do
    from(l in Link)
    |> join(:left, [l], s in Signup, s.custom_signup_link_id == l.id)
    |> join(:left, [l, s], stu in Student, stu.id == s.student_id)
    |> group_by([l], l.id)
    |> select([l, s, stu], %{link_id: l.id, count: count(stu.id)})
  end
end