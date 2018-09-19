defmodule SkollerWeb.EmailPreferenceView do
  use SkollerWeb, :view
  alias SkollerWeb.EmailPreferenceView

  def render("index.json", %{email_preferences: email_preferences}) do
    render_many(email_preferences, EmailPreferenceView, "email_preference.json")
  end

  def render("show.json", %{email_preference: email_preference}) do
    render_one(email_preference, EmailPreferenceView, "email_preference.json")
  end

  def render("email_preference.json", %{email_preference: email_preference}) do
    %{
      is_unsubscribed: email_preference.is_unsubscribed,
      email_type_id: email_preference.email_type_id,
      user_id: email_preference.user_id,
      id: email_preference.id
    }
  end
end
