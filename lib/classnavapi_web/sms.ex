defmodule ClassnavapiWeb.Sms do
  @moduledoc """
    Provides SMS utilities.
  """

  alias ExTwilio.Message

  @from_phone "+16152099126"
  @test_phone "+15005550006"

  @verification_msg1 "Your Skoller verification code is "
  @verification_msg2 ". #SkollerAtMe"

  def verify_phone(phone, code) do
    case Mix.env do
      :prod -> Message.create(
                to: "+1" <> phone,
                from: @from_phone,
                body: @verification_msg1 <> code <> @verification_msg2
              )
      _ -> Message.create(
              to: "+1" <> phone,
              from: @test_phone,
              body: @verification_msg1 <> code <> @verification_msg2
            )
    end
    
  end
end