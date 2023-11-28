defmodule Skoller.Services.Sms do
  @moduledoc """
  Provides SMS utilities.
  """

  alias ExTwilio.Message

  require Logger

  @from_phone "+16157035170"
  @test_phone "+15005550006"

  @doc """
  Sends a message.

  Uses `Mix.env/0` to only send actual texts in `:prod` mode.
  """
  def send_sms(phone, body) do
    Logger.info("Sending sms to " <> "+1" <> phone)

    case Mix.env() do
      :prod ->
        Message.create(
          to: "+1" <> phone,
          from: @from_phone,
          body: body
        )

      _ ->
        Message.create(
          to: "+1" <> phone,
          from: @test_phone,
          body: body
        )
    end
  end
end
