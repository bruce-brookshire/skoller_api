defmodule Skoller.Users.EmailPreferences do
  @moduledoc """
  The user email preferences context.
  """
  alias Skoller.Users.EmailPreference
  alias Skoller.Users
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Gets email preferences for a user.

  Returns
  `%{email_preferences: [], user_unsubscribed: boolean}`
  """
  def get_email_preferences_by_user(user_id) do
    ep = from(ep in EmailPreference)
    |> where([ep], ep.user_id == ^user_id)
    |> Repo.all()

    user = Users.get_user_by_id!(user_id)

    Map.new()
    |> Map.put(:email_preferences, ep)
    |> Map.put(:user_unsubscribed, user.is_unsubscribed)
  end

  @doc """
  Gets email preferences for a user.
  """
  def get_email_preferences_by_id!(id) do
    Repo.get!(EmailPreference, id)
  end

  @doc """
  Creates a email_preference.

  ## Examples

      iex> create_email_preference(%{field: value})
      {:ok, %EmailPreference{}}

      iex> create_email_preference(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_email_preference(attrs \\ %{}) do
    %EmailPreference{}
    |> EmailPreference.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a email_preference.

  ## Examples

      iex> update_email_preference(email_preference, %{field: new_value})
      {:ok, %EmailPreference{}}

      iex> update_email_preference(email_preference, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_email_preference(%EmailPreference{} = email_preference, attrs) do
    email_preference
    |> EmailPreference.upd_changeset(attrs)
    |> Repo.update()
  end
end