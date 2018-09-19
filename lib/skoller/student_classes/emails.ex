defmodule Skoller.StudentClasses.Emails do
  @moduledoc """
  Defines emails based on student classes
  """

  alias Skoller.Mailer
  alias Skoller.Users.EmailPreferences

  import Bamboo.Email

  require EEx
  EEx.function_from_file :defp, :build_no_classes_body, System.cwd() <> "/lib/skoller/student_classes/no_classes.html.eex", []

  @from_email "noreply@skoller.co"
  @no_classes_name "No Classes Email"

  def send_no_classes_emails(students) do
    students
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(List.first(&1.users), @no_classes_name))
    |> Enum.map(&build_no_classes_email(List.first(&1.users)))
    |> Enum.each(&Mailer.deliver_later(&1))
  end

  defp build_no_classes_email(user) do
    new_email()
    |> to(user.email)
    |> from(@from_email)
    |> subject("🚨 URGENT: You have no classes 🚨")
    |> html_body(build_no_classes_body())
    |> text_body("test")
  end
end