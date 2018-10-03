defmodule Skoller.StudentClasses.Emails do
  @moduledoc """
  Defines emails based on student classes
  """

  alias Skoller.Users.EmailPreferences
  alias Skoller.Services.MarketingEmail

  @no_classes_id 100

  def send_no_classes_emails(students) do
    students
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(List.first(&1.users), @no_classes_id))
    |> Enum.map(&send_no_classes_email(List.first(&1.users)))
  end

  defp send_no_classes_email(user) do
    user_id = user.id |> to_string
    text_body = "test"
    MarketingEmail.send_email(user_id, user.email, "🚨 URGENT: You have no classes 🚨", "no_classes.html", text_body)
  end
end