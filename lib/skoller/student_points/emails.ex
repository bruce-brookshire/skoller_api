defmodule Skoller.StudentPoints.Emails do
  @moduledoc """
  Defines emails based on student points
  """

  alias Skoller.Users.EmailPreferences
  alias Skoller.Services.MarketingEmail
  alias Skoller.EmailLogs
  alias Skoller.Users.Students

  @one_thousand_points_id 300

  def send_one_thousand_points_email(student_id) do
    user = Students.get_user_by_student_id(student_id)
    email_count = EmailLogs.get_sent_emails_by_user_and_type(user.id, @one_thousand_points_id) |> Enum.count()

    if email_count == 0 do
      if EmailPreferences.check_email_subscription_status(user, @one_thousand_points_id) do
        send_no_classes_email(user)
      end
    end
  end

  defp send_no_classes_email(user) do
    user_id = user.id |> to_string
    subject = "Sign up for your classes so you can party harder!  🍻"
    MarketingEmail.send_email(user_id, user.email, subject, :one_thousand_points, @one_thousand_points_id)
  end
end