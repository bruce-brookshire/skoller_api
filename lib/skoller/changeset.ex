defmodule Skoller.Changeset do
  @moduledoc """
  A module for manipulating `Ecto.Changeset`
  """

  import Ecto.Changeset

  @doc """
  Deletes all tuples in `keyword` from the changeset.
  """
  def delete_changes(changeset, keyword) do
    keyword |> Enum.reduce(changeset, &(&2 |> delete_change(elem(&1, 0))))
  end

  @doc """
  Returns a `Keyword` of `changeset.changes` that do not exist in `original`
  """
  def get_new_changes(changeset, original) do
    changeset.changes
    |> Map.to_list()
    |> Enum.filter(&old_field_not_set(&1, original))
    |> convert_keyword_to_map()
  end

  defp convert_keyword_to_map(keyword) do
    keyword |> Enum.reduce(%{}, &(&2 |> Map.put(elem(&1, 0), elem(&1, 1))))
  end

  defp old_field_not_set(tuple, original) do
    original |> Map.get(elem(tuple, 0)) |> is_nil()
  end
end
