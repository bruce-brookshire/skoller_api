defmodule Skoller.Users.Emails do
  @moduledoc """
  A Context module for sending emails for users
  """

  alias Skoller.Services.TriggeredEmail

  @forgot_subject "Forgot Password"
  @reset_password_route "/reset_password"

  def send_forgot_pass_email(user, token) do
    reset_path = to_string(System.get_env("WEB_URL")) <> @reset_password_route <> "?token=" <> token
    TriggeredEmail.send_email(user.email, @forgot_subject, :forgot_password, [reset_path: reset_path])
  end
end