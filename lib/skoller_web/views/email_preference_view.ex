defmodule SkollerWeb.EmailPreferenceView do
  use SkollerWeb, :view
  alias SkollerWeb.EmailPreferenceView

  def render("index.json", %{user_email_preferences: user_email_preferences}) do
    %{data: render_many(user_email_preferences, EmailPreferenceView, "email_preference.json")}
  end

  def render("show.json", %{email_preference: email_preference}) do
    %{data: render_one(email_preference, EmailPreferenceView, "email_preference.json")}
  end

  def render("email_preference.json", %{email_preference: email_preference}) do
    %{id: email_preference.id,
      is_unsubscribed: email_preference.is_unsubscribed,
      is_no_classes_email: email_preference.is_no_classes_email,
      is_class_setup_email: email_preference.is_class_setup_email}
  end
end
