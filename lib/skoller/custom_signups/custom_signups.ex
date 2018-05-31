defmodule Skoller.CustomSignups do
  alias Skoller.CustomSignups.Link
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

  def update_link(link_old, params) do
    link_old
    |> Link.changeset_update(params)
    |> Repo.update()
  end
end