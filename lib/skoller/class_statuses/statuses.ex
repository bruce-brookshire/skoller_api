defmodule Skoller.ClassesStatuses do
  @moduledoc """
    Context module for class statuses.
  """

  alias Skoller.Repo
  alias Skoller.ClassesStatuses.Status

  @doc """
  Gets a class status by status id

  ## Returns
  `Skoller.ClassesStatuses.Status` or raises
  """
  def get_status_by_id!(id) do
    Repo.get!(Status, id)
  end

  @doc """
  Gets all class statuses

  ## Returns
  `[Skoller.ClassesStatuses.Status]` or `[]`
  """
  def get_statuses() do
    Repo.all(Status)
  end
end