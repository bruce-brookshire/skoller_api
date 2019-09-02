defmodule Skoller.Users.Emails do
  @moduledoc """
  A Context module for sending emails for users
  """

  alias Skoller.Services.SesMailer

  def send_forgot_pass_email(user, token) do
    reset_path = to_string(System.get_env("WEB_URL")) <> "/reset_password?token=" <> token

    SesMailer.send_individual_email(
      %{to: user.email, form: %{reset_path: reset_path}},
      "forgot_password"
    )
  end
end
