defmodule Skoller.CancellationReasons do
  alias Skoller.Repo
  alias Skoller.CancellationReasons.CancellationReason

  def create(params) do
    %CancellationReason{}
    |> CancellationReason.changeset(params)
    |> Repo.insert()
  end
end