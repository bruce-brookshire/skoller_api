defmodule Skoller.EmailTypes do
  @moduledoc """
  Context module for email types.
  """

  alias Skoller.Repo
  alias Skoller.EmailTypes.EmailType

  import Ecto.Query

  @doc """
  Gets all email types

  ## Returns
  `[Skoller.EmailTypes]` or `[]`
  """
  def all() do
    EmailType
    |> order_by(asc: :id)
    |> Repo.all()
  end

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