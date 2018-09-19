defmodule SkollerWeb.EmailPreferenceView do
  use SkollerWeb, :view
  alias SkollerWeb.EmailPreferenceView

  def render("show.json", %{email_preference: email_preference}) do
    render_one(email_preference, EmailPreferenceView, "email_preference.json")
  end

  def render("email_preference.json", %{email_preference: email_preference}) do
    %{is_unsubscribed: email_preference.is_unsubscribed,
      is_no_classes_email: email_preference.is_no_classes_email,
      is_class_setup_email: email_preference.is_class_setup_email}
  end
end
