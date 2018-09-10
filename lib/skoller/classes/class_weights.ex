defmodule Skoller.Classes.Weights do
  @moduledoc """
  Context module for class weights
  """

  alias Skoller.Repo
  alias Skoller.Weights.Weight
  
  import Ecto.Query

  @doc """
  Gets all weights for a class.

  Returns `[Skoller.Weights.Weight]` or `[]`
  """
  def get_class_weights(class_id) do
    from(w in Weight)
    |> where([w], w.class_id == ^class_id)
    |> Repo.all
  end

  @doc """
  Gets a weight by the class and weight id.

  Returns `Skoller.Weights.Weight` or `nil`
  """
  def get_class_weight_by_ids(class_id, weight_id) do
    Repo.get_by(Weight, class_id: class_id, id: weight_id)
  end
end