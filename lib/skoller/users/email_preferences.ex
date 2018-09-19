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
  def get_email_preferences_by_id(id) do
    Repo.get(EmailPreference, id)
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

  def update_user_subscription(user_id, is_unsubscribed) do
    Users.get_user_by_id!(user_id)
    |> Users.update_user(%{is_unsubscribed: is_unsubscribed})
  end

  @doc """
  Upserts multiple email_preferences.
  """
  def upsert_email_preferences(email_preferences, user_id) do
    Enum.map(email_preferences, &process_email_preference(&1, user_id))
  end

  defp process_email_preference(%{"id" => id} = email_preference, user_id) do
    email_preference_old = get_email_preferences_by_id(id)

    case user_id == email_preference_old.user_id do
      true -> 
        update_email_preference(email_preference_old, email_preference)
      false ->
        {:error, "non-matching ids"}
    end
  end

  defp process_email_preference(email_preference) do
    create_email_preference(email_preference)
  end
end