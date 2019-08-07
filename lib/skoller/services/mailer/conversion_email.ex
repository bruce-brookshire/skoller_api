defmodule Skoller.Services.ConversionEmail do
  @moduledoc """
  A helper module for sending triggered emails
  """
  use Bamboo.Phoenix, view: SkollerWeb.ConversionView

  alias Skoller.Services.Mailer

  import Bamboo.Email

  require Logger

  @from_email "noreply@skoller.co"
  @reply_to_email "support@skoller.co"

  def send_email(email_adr, subject, template, user_id, assigns \\ []) do
    new_email()
    |> from({"Skoller", @from_email})
    |> to(email_adr)
    |> subject(subject)
    |> put_header("Reply-To", @reply_to_email)
    |> put_assigns(assigns)
    |> assign(:unsub_path, System.get_env("WEB_URL") <> "/unsubscribe/" <> user_id)
    |> render(template)
    |> Mailer.deliver_now()
  end

  defp put_assigns(email, []), do: email

  defp put_assigns(email, assigns) do
    assigns
    |> Enum.reduce(email, &assign(&2, elem(&1, 0), elem(&1, 1)))
  end
end
