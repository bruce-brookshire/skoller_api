defmodule Skoller.MapErrors do
  @moduledoc """
  A helper module for `Enum.map/2` and `Skoller.Repo` functions returning a tuple
  """

  @doc """
  This will return true if a tuple is passed that contains {:error}
  """
  def check_tuple({:error, _val}), do: true
  def check_tuple(_tuple), do: false
end