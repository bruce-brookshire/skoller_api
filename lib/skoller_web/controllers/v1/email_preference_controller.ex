defmodule SkollerWeb.Api.V1.EmailPreferenceController do
  use SkollerWeb, :controller

  alias Skoller.Users.EmailPreferences
  alias Skoller.Users
  alias SkollerWeb.EmailPreferenceView
  alias SkollerWeb.UserEmailPreferenceView

  def create(conn, %{"email" => email, "user_id" => user_id} = params) do
    case Users.get_user_by_email(email) do
      nil -> 
        conn |> send_resp(403, "")
      user ->
        if user_id != user.id |> to_string do
          conn |> send_resp(403, "")
        end
    end

    case EmailPreferences.create_email_preference(params) do
      {:ok, email_preference} ->
        conn |> render(EmailPreferenceView, "show.json", email_preference: email_preference)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"user_id" => user_id}) do
    user_email_preference = EmailPreferences.get_email_preferences_by_user(user_id)
    render(conn, UserEmailPreferenceView, "show.json", user_email_preference: user_email_preference)
  end

  def update(conn, %{"user_id" => user_id, "id" => id, "email" => email} = params) do
    case Users.get_user_by_email(email) do
      nil -> 
        conn |> send_resp(403, "")
      user ->
        if user_id != user.id |> to_string do
          conn |> send_resp(403, "")
        end
    end

    email_preference = EmailPreferences.get_email_preferences_by_id!(id)

    if email_preference.user_id |> to_string() != user_id do
      conn |> send_resp(403, "")
    end

    case EmailPreferences.update_email_preference(email_preference, params) do
      {:ok, email_preference} ->
        conn |> render(EmailPreferenceView, "show.json", email_preference: email_preference)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
