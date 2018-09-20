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
  @no_classes_name "No Classes Email"

  def send_no_classes_emails(students) do
    students
    |> Enum.filter(&EmailPreferences.check_email_subscription_status(List.first(&1.users), @no_classes_name))
    |> Enum.map(&build_no_classes_email(List.first(&1.users)))
    |> Enum.each(&deliver_message(&1))
  end

  defp deliver_message(%{email: email, user_id: user_id}) do
    try do
      Mailer.deliver_now(email)
    rescue
      error in Bamboo.SMTPAdapter.SMTPError ->
        case error.raw do
          {:retries_exceeded, _} ->
            EmailPreferences.update_user_subscription(user_id, true)
            Logger.info("unsubscribed user: " <> user_id |> to_string)
          error ->
            Logger.error(inspect(error))
        end
        reraise error, System.stacktrace
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