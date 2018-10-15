defmodule Skoller.Classes.Weights do
  @moduledoc """
  A context module for class weights
  """

  alias Skoller.Repo
  alias Skoller.Weights.Weight
  
  import Ecto.Query
  
  @doc """
  Gets weights by class.

  ## Returns
  `[Skoller.Weights.Weight]` or `nil`
  """
  def get_weights_by_class_id(class_id) do
    from(w in Weight)
    |> where([w], w.class_id == ^class_id)
    |> Repo.all()
  end
end
