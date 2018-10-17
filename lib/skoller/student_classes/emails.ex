defmodule Skoller.StudentClasses.Emails do
  @moduledoc """
  Defines emails based on student classes
  """

  alias Skoller.Users.EmailPreferences
  alias Skoller.Services.MarketingEmail

  @no_classes_id 100
  @needs_setup_id 200

  @doc """
  Sends the no classes email to the list of `students`
  """
  def send_no_classes_emails(students) do
    students
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(List.first(&1.users), @no_classes_id))
    |> Enum.map(&send_no_classes_email(List.first(&1.users)))
  end

  @doc """
  Sends the class needs setup email to the list of `students`
  """
  def send_needs_setup_emails(students) do
    students
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(List.first(&1.users), @needs_setup_id))
    |> Enum.map(&send_needs_setup_email(List.first(&1.users)))
  end

  defp send_no_classes_email(user) do
    user_id = user.id |> to_string
    subject = "Sign up for your classes so you can party harder!  🍻"
    MarketingEmail.send_email(user_id, user.email, subject, :no_classes, @no_classes_id)
  end

  defp send_needs_setup_email(user) do
    user_id = user.id |> to_string
    subject = "Set up your classes and get life on track"
    MarketingEmail.send_email(user_id, user.email, subject, :needs_setup, @needs_setup_id)
  end
end