defmodule Skoller.Weights do
  @moduledoc """
  The context module for weights.
  """

  alias Skoller.Repo
  alias Skoller.Weights.Weight

  @doc """
  Gets a weight by id.

  ## Returns
  `Skoller.Weights.Weight` or `Ecto.NoResultsError`
  """
  def get!(id) do
    Repo.get!(Weight, id)
  end

  @doc """
  Inserts a weight.

  ## Returns
  `{:ok, %Skoller.Weights.Weight{}` or `{:error, Ecto.Changeset}``
  """
  def insert(params) do
    Weight.changeset_insert(%Weight{}, params)
    |> Repo.insert()
  end

  @doc """
  Updates a weight.

  ## Returns
  `{:ok, %Skoller.Weights.Weight{}` or `{:error, Ecto.Changeset}``
  """
  def update(weight_old, params) do
    Weight.changeset_update(weight_old, params)
    |> Repo.update()
  end

  @doc """
  Deletes a weight.

  ## Returns
  `{:ok, %Skoller.Weights.Weight{}` or `{:error, Ecto.Changeset}``
  """
  def delete(%Weight{} = weight) do
    Repo.delete(weight)
  end
end