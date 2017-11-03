defmodule Classnavapi.Helpers.ChangesetValidation do

  @moduledoc """
  
  Provides helper functions for changeset validation

  """

  import Ecto.Changeset

  defp compare_dates(changeset, nil, _, _), do: changeset
  defp compare_dates(changeset, _, nil, _), do: changeset
  defp compare_dates(changeset, start_val, end_val, start_date) do
    changeset |> compare_dates(Date.compare(start_val, end_val), start_date)
  end
  defp compare_dates(changeset, :lt, _), do: changeset
  defp compare_dates(changeset, _, start_date) do
     changeset |> add_error(start_date, "Start date occurs on or after end date.")
  end
  
  def validate_dates(changeset, start_date, end_date) do
    start_val = changeset |> get_field(start_date)
    end_val = changeset |> get_field(end_date)
    changeset |> compare_dates(start_val, end_val, start_date)
  end
end
