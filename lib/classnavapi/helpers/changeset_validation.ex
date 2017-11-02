defmodule Classnavapi.Helpers.ChangesetValidation do

  @moduledoc """
  
  Provides helper functions for changeset validation

  """

  import Ecto.Changeset

  def validate_dates(changeset, start_date, end_date) do
    start_val = changeset |> get_field(start_date)
    end_val = changeset |> get_field(end_date)
    case start_val < end_val do
      true -> changeset
      false -> add_error(changeset, start_date, "Start date occurs on or after end date.")
    end
  end
end
