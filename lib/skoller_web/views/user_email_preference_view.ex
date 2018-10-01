defmodule SkollerWeb.UserEmailPreferenceView do
  use SkollerWeb, :view
  alias SkollerWeb.EmailPreferenceView
  alias SkollerWeb.UserEmailPreferenceView

  def render("show.json", %{user_email_preference: user_email_preference}) do
    render_one(user_email_preference, UserEmailPreferenceView, "user_email_preference.json")
  end

  def render("user_email_preference.json", %{user_email_preference: %{email_preferences: email_preferences, user_unsubscribed: user_unsubscribed}}) do
    %{
      email_preferences: render_many(email_preferences, EmailPreferenceView, "email_preference.json"),
      user_unsubscribed: user_unsubscribed
    }
  end
end
