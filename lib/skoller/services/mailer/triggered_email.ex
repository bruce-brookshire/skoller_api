defmodule Skoller.Services.TriggeredEmail do
  @moduledoc """
  A helper module for sending triggered emails
  """
  use Bamboo.Phoenix, view: SkollerWeb.TriggeredView

  alias Skoller.Services.Mailer
  alias Skoller.Repo

  import Bamboo.Email

  require Logger

  @from_email "noreply@skoller.co"

  def send_email(user_id, email_adr, subject, template, email_type_id) do
    base_email(user_id)
    |> to(email_adr)
    |> subject(subject)
    |> render(template)
    |> Mailer.deliver_later()
  end

  defp base_email(user_id) do
    new_email()
    |> from(@from_email)
    |> put_layout({SkollerWeb.LayoutView, :triggered})
  end
end