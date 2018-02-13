defmodule Classnavapi.Mailer do
  use Bamboo.Mailer, otp_app: :classnavapi

  @divider "--"
  @skoller "The Skoller Team"
  @logo_url "https://www.skoller.co/src/assets/images/logo-wide-blue@1x.png"

  def signature() do
    "<h3 style='margin-bottom: 0'>" <> @divider <> "</h3>" <> 
    "<h3 style='margin: 0'>" <> @skoller <> "</h3>" <>
    "<a href=" <> to_string(System.get_env("WEB_URL")) <> ">" <>  
    "<img src=" <> @logo_url <> " alt = logo style='width: 120px'></a>"
  end

  def text_signature() do
    @divider <> "\n" <>
    @skoller
  end
end