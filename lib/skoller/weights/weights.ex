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
  def insert(user_id, params) do
    Weight.changeset_insert(%Weight{}, params)
    |> Ecto.Changeset.change(%{created_by: user_id, updated_by: user_id, created_on: params["created_on"]})
    |> Repo.insert()
  end

  @doc """
  Updates a weight.

  ## Returns
  `{:ok, %Skoller.Weights.Weight{}` or `{:error, Ecto.Changeset}``
  """
  def update(user_id, weight_old, params) do
    Weight.changeset_update(weight_old, params)
    |> Ecto.Changeset.change(%{updated_by: user_id})
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