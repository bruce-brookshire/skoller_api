defmodule SkollerWeb.EmailPreferenceController do
  use SkollerWeb, :controller

  alias Skoller.Users.EmailPreferences

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  @admin_role 200
  
  plug :verify_role, %{roles: [@admin_role, @student_role]}

  def create(conn, params) do
    case EmailPreferences.create_email_preference(params) do
      {:ok, email_preference} ->
        conn |> render("show.json", email_preference: email_preference)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"user_id" => user_id}) do
    email_preference = EmailPreferences.get_email_preferences_by_user(user_id)
    render(conn, "show.json", email_preference: email_preference)
  end

  def update(conn, %{"user_id" => user_id} = params) do
    email_preference = EmailPreferences.get_email_preferences_by_user!(user_id)

    case EmailPreferences.update_email_preference(email_preference, params) do
      {:ok, email_preference} ->
        conn |> render("show.json", email_preference: email_preference)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
