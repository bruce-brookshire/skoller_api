defmodule Skoller.StudentClasses.Emails do
  @moduledoc """
  Defines emails based on student classes
  """

  alias Skoller.Mailer
  alias Skoller.Users.EmailPreferences

  import Bamboo.Email

  require Logger
  require EEx
  EEx.function_from_file :defp, :build_no_classes_body, System.cwd() <> "/lib/skoller/student_classes/no_classes.html.eex", [:unsub_path]

  @from_email "noreply@skoller.co"
  @no_classes_id 100

  def send_no_classes_emails(students) do
    students
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(List.first(&1.users), @no_classes_id))
    |> Enum.map(&build_no_classes_email(List.first(&1.users)))
    |> Enum.each(&deliver_message(&1))
  end

  defp deliver_message(%{email: email, user_id: user_id}) do
    try do
      Logger.info("Sending email to: " <> user_id |> to_string)
      Mailer.deliver_now(email)
    rescue
      error ->
        Logger.error(inspect(error))
    end
  end

  defp build_no_classes_email(user) do
    user_id = user.id |> to_string
    email = new_email()
    |> to(user.email)
    |> from(@from_email)
    |> subject("🚨 URGENT: You have no classes 🚨")
    |> html_body(build_no_classes_body(System.get_env("WEB_URL") <> "/unsubscribe/" <> user_id))
    |> text_body("test")

    Map.new
    |> Map.put(:email, email)
    |> Map.put(:user_id, user_id)
  end
end