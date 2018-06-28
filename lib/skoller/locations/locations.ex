defmodule Skoller.Locations do
  @moduledoc """
  Context module for locations
  """

  alias Skoller.Repo
  alias Skoller.Locations.State

  @doc """
  Gets all states

  ## Returns
  `[Skoller.Locations.State]` or `[]`
  """
  def get_states() do
    Repo.all(State)
  end
end