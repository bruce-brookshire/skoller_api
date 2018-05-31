defmodule Skoller.CustomSignups do
  alias Skoller.CustomSignups.Link
  alias Skoller.CustomSignups.Signup
  alias Skoller.Repo

  def create_link(params) do
    %Link{}
    |> Link.changeset(params)
    |> Repo.insert()
  end

  def get_links() do
    Repo.all(Link)
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
end