defmodule SkollerWeb.Api.V1.EmailPreferenceController do
  use SkollerWeb, :controller

  alias Skoller.Users.EmailPreferences
  alias SkollerWeb.EmailPreferenceView

  def create(conn, params) do
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
    email_preferences = EmailPreferences.get_email_preferences_by_user(user_id)
    render(conn, EmailPreferenceView, "index.json", email_preferences: email_preferences)
  end

  def update(conn, %{"user_id" => user_id, "id" => id} = params) do
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
