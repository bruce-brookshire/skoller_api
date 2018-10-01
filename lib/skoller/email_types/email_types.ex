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

  @doc """
  Updates an email type.

  ## Returns
  `{:ok, Skoller.EmailTypes.EmailType}` or {:error, changeset}
  """
  def update(old_email_type, new_email_type) do
    EmailType.update_changeset(old_email_type, new_email_type)
    |> Repo.update()
  end
end