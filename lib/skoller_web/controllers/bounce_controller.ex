defmodule SkollerWeb.Api.BounceController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Users.EmailPreferences
  alias Skoller.Users

  require Logger

  def bounce(conn, %{"Message" => message} = params) do
    Logger.warn("Recieved SNS message")

    case params["SubscribeURL"] do
      nil ->
        IO.inspect(message["eventType"])
        handle_notification(message)

      url ->
        HTTPoison.get(url)
    end

    conn |> send_resp(204, "")
  end

  defp handle_notification(%{"eventType" => "Complaint", "complaint" => complaint}) do
    Logger.info("Recieved complaint for email " <> inspect(complaint["complainedRecipients"]))

    complaint["complainedRecipients"] |> Enum.each(&unsubscribe_email(&1["emailAddress"]))
  end

  defp handle_notification(%{"eventType" => "Bounce", "bounce" => bounce}) do
    Logger.info("Recieved bounce for email " <> inspect(bounce["bouncedRecipients"]))

    bounce["bouncedRecipients"] |> Enum.each(&unsubscribe_email(&1["emailAddress"]))
  end

  defp handle_notification(msg) when is_binary(msg),
    do: IO.puts("Failed with binary msg: " <> msg)

  defp handle_notification(msg), do: IO.puts("Failed without binary msg")

  defp unsubscribe_email(email) do
    IO.inspect(email)

    case Users.get_user_by_email(email) do
      nil ->
        IO.puts("Failed to get user")

      user ->
        EmailPreferences.update_user_subscription(user.id, true)
    end
  end
end
