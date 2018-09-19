defmodule Skoller.EmailTypes do
  @moduledoc """
  Context module for email types.
  """

  alias Skoller.Repo
  alias Skoller.EmailTypes.EmailType

  @doc """
  Gets all email types

  Returns [Skoller.EmailTypes] or []
  """
  def all(), do: Repo.all(EmailType)
end