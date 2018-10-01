defmodule Skoller.EmailTypes do
  @moduledoc """
  Context module for email types.
  """

  alias Skoller.Repo
  alias Skoller.EmailTypes.EmailType

  @doc """
  Gets all email types

  ## Returns
  `[Skoller.EmailTypes]` or `[]`
  """
  def all(), do: Repo.all(EmailType)

  @doc """
  Gets an email type by id

  ## Returns
  `Skoller.EmailTypes` or `nil`
  """
  def get!(id) do
    Repo.get(EmailType, id)
  end
end