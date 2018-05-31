defmodule Skoller.CustomSignups do
  alias Skoller.CustomSignups.Link
  alias Skoller.CustomSignups.Signup
  alias Skoller.Repo
  alias Skoller.Students.Student

  import Ecto.Query

  def create_link(params) do
    %Link{}
    |> Link.changeset(params)
    |> Repo.insert()
  end

  def get_links() do
    from(l in Link)
    |> join(:inner, [l], c in subquery(get_link_student_count_subquery()), c.link_id == l.id)
    |> select([l, c], %{link: l, signup_count: c.count})
    |> Repo.all()
  end

  def get_link_by_id(id) do
    Repo.get(Link, id)
  end

  def get_link_by_link(link) do
    Repo.get_by(Link, link: link)
  end

  def update_link(link_old, params) do
    link_old
    |> Link.changeset_update(params)
    |> Repo.update()
  end

  def track_signup(student_id, link_id) do
    Repo.insert(%Signup{custom_signup_link_id: link_id, student_id: student_id})
  end

  defp get_link_student_count_subquery() do
    from(l in Link)
    |> join(:left, [l], s in Signup, s.custom_signup_link_id == l.id)
    |> join(:left, [l, s], stu in Student, stu.id == s.student_id)
    |> group_by([l], l.id)
    |> select([l, s, stu], %{link_id: l.id, count: count(stu.id)})
  end
end