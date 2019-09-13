defmodule SkollerWeb.Api.BounceController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Users.EmailPreferences
  alias Skoller.Users

  require Logger

  def bounce(conn, %{"Message" => message} = params) do
    case params["SubscribeURL"] do
      nil ->
        message
        |> IO.inspect()
        |> handle_notification()

      url ->
        HTTPoison.get(url)
    end

    conn |> send_resp(204, "")
  end

  defp handle_notification(%{"notificationType" => "Complaint", "complaint" => complaint}) do
    Logger.info("Recieved complaint for email " <> inspect(complaint["complainedRecipients"]))

    complaint["complainedRecipients"] |> Enum.each(&unsubscribe_email(&1["emailAddress"]))
  end

  defp handle_notification(%{"notificationType" => "Bounce", "bounce" => bounce}) do
    Logger.info("Recieved bounce for email " <> inspect(bounce["bouncedRecipients"]))

    bounce["bouncedRecipients"] |> Enum.each(&unsubscribe_email(&1["emailAddress"]))
  end

  defp handle_notification(msg) when is_binary(msg), do: IO.puts(msg)

  defp unsubscribe_email(email) do
    case Users.get_user_by_email(email) do
      nil ->
        nil

      user ->
        EmailPreferences.update_user_subscription(user.id, true)
    end
  end
end
