defmodule SkollerWeb.Api.V1.EmailPreferenceController do
  use SkollerWeb, :controller

  alias Skoller.Users.EmailPreferences
  alias Skoller.Users
  alias SkollerWeb.EmailPreferenceView
  alias SkollerWeb.UserEmailPreferenceView
  alias Skoller.MapErrors

  def index(conn, %{"user_id" => user_id}) do
    user_email_preference = EmailPreferences.get_email_preferences_by_user(user_id)
    render(conn, UserEmailPreferenceView, "show.json", user_email_preference: user_email_preference)
  end

  def update(conn, %{"user_id" => user_id, "email" => email} = params) do
    case Users.get_user_by_email(email) do
      nil -> 
        conn |> send_resp(403, "")
      user ->
        if user_id != user.id |> to_string do
          conn |> send_resp(403, "")
        end
    end

    email_preferences = EmailPreferences.upsert_email_preferences(params["email_preferences"])

    case EmailPreferences.update_user_subscription(user_id, params["user_unsubscribed"]) do
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
      {:ok, _user} ->
        nil
    end

    case email_preferences |> Enum.find({:ok, email_preferences}, &MapErrors.check_tuple(&1)) do
      {:ok, _email_preferences} ->
        user_email_preference = EmailPreferences.get_email_preferences_by_user(user_id)
        render(conn, UserEmailPreferenceView, "show.json", user_email_preference: user_email_preference)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
