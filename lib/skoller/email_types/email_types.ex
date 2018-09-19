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

  def get_by_name(name) do
    Repo.get_by(EmailType, name: name)
  end
end