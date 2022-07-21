defmodule Skoller.Students.Sms do
  @moduledoc """
  A context module for sms messages for students.
  """

  alias Skoller.Services.Sms

  require Logger

  @verification_msg1 "Your Skoller verification code is "
  @verification_msg2 ". #SkollerAtMe"

  @login_msg1 "Your Skoller login code is "
  @login_msg2 ". #SkollerAtMe"

  @doc """
  Sends a verification text to the `phone`.

  Uses `Mix.env/0` to only send actual texts in `:prod` mode.
  """
  def verify_phone(phone, code) do
    Logger.info("Sending verification code")
    if (Mix.env() == :dev) do
      IO.puts "VERIFICATION CODE: #{code}"
    end
    Sms.send_sms(phone, @verification_msg1 <> code <> @verification_msg2)
  end

  def login_phone(phone, code) do
    Sms.send_sms(phone, @login_msg1 <> code <> @login_msg2)
  end
end
