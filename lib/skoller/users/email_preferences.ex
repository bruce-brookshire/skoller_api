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

  @doc """
  Updates a user's overall subscription status to marketing emails.

  Returns
  `{:ok, user}` or `{:error, changeset}`
  """
  # TODO make this accept user objects too
  def update_user_subscription(user_id, is_unsubscribed) do
    Users.get_user_by_id!(user_id)
    |> Users.update_user(%{is_unsubscribed: is_unsubscribed})
  end

  @doc """
  Checks the subscription status of a specific email type and user.

  Returns true if the email can be sent, and false if not.
  """
  def check_email_subscription_status(%{is_unsubscribed: true}, _email_type_id), do: false
  def check_email_subscription_status(user, email_type_id) do
    case Repo.get_by(EmailPreference, user_id: user.id, email_type_id: email_type_id) do
      nil -> true
      email_preference -> !email_preference.is_unsubscribed
    end
  end

  @doc """
  Upserts multiple email_preferences.
  """
  def upsert_email_preferences(nil, _user_id), do: []
  def upsert_email_preferences(email_preferences, user_id) do
    Enum.map(email_preferences, &process_email_preference(&1, user_id))
  end

  defp process_email_preference(email_preference, user_id) do
    case get_email_preference_by_email_type(email_preference["email_type_id"], user_id) do
      nil ->
        email_preference
        |> Map.put("user_id", user_id)
        |> create_email_preference()
      email_preference_old ->
        update_email_preference(email_preference_old, email_preference)
    end
  end

  defp get_email_preference_by_email_type(email_type_id, user_id) do
    Repo.get_by(EmailPreference, email_type_id: email_type_id, user_id: user_id)
  end
end