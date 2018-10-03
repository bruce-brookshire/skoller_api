defmodule Skoller.Services.Mailer do
  @moduledoc """
  Module for sending emails using `Bamboo.Mailer`
  """
  use Bamboo.Mailer, otp_app: :skoller
end