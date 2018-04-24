defmodule Skoller.Locations do
  alias Skoller.Repo
  alias Skoller.Locations.State

  def get_states() do
    Repo.all(State)
  end
end