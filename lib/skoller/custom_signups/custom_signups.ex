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
end