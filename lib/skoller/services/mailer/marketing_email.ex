defmodule Skoller.Services.MarketingEmail do
  @moduledoc """
  A helper module for sending marketing emails
  """
  use Bamboo.Phoenix, view: SkollerWeb.EmailView

  alias Skoller.Services.Mailer
  alias Skoller.EmailLogs.EmailLog
  alias Skoller.Repo

  import Bamboo.Email

  require Logger

  @from_email "noreply@skoller.co"
  @reply_to_email "support@skoller.co"

  def send_email(user_id, email_adr, subject, template, email_type_id) do
    base_email(user_id)
    |> to(email_adr)
    |> subject(subject)
    |> render(template)
    |> put_header("Reply-To", @reply_to_email)
    |> deliver_message(user_id, email_type_id)
  end

  defp deliver_message(email, user_id, email_type_id) do
    try do
      Logger.info("Sending email to: " <> user_id |> to_string)
      Repo.insert(%EmailLog{user_id: user_id |> String.to_integer(), email_type_id: email_type_id})
      Mailer.deliver_now(email)
    rescue
      error ->
        Logger.error(inspect(error))
    end
  end

  defp base_email(user_id) do
    new_email()
    |> from({"Skoller", @from_email})
    |> put_layout({SkollerWeb.LayoutView, :email})
    |> assign(:unsub_path, System.get_env("WEB_URL") <> "/unsubscribe/" <> user_id)
  end
end