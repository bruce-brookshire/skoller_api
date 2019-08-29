defmodule Skoller.Services.TriggeredEmail do
  @moduledoc """
  A helper module for sending triggered emails
  """

  require Logger

  @from_email "noreply@skoller.co"
  @reply_to_email "support@skoller.co"

  def send_email(email_adr, subject, template, assigns \\ []) do
    # base_email()
    # |> to(email_adr)
    # |> subject(subject)
    # |> put_header("Reply-To", @reply_to_email)
    # |> put_assigns(assigns)
    # |> render(template)
    # |> Mailer.deliver_later()
  end

  defp base_email() do
    # new_email()
    # |> from({"Skoller", @from_email})
    # |> assign(:web_home_path, System.get_env("WEB_URL"))
    # |> put_layout({SkollerWeb.LayoutView, :triggered})
  end

  defp put_assigns(email, []), do: email
  defp put_assigns(email, assigns) do
    assigns |> Enum.reduce(email, &assign(&2, elem(&1, 0), elem(&1, 1)))
  end
end