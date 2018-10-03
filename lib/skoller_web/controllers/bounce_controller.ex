defmodule SkollerWeb.Api.BounceController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Users.EmailPreferences
  alias Skoller.Users

  require Logger

  def bounce(conn, %{"Message" => message}) do
    decoded_message = Poison.decode!(message)
    handle_notification(decoded_message)
    conn |> send_resp(204, "")
  end

  def bounce(conn, params) do
    case params["SubscribeURL"] do
      nil -> 
        Logger.error(inspect(params))
        conn |> send_resp(403, "")
      url ->
        HTTPoison.get(url)
        conn |> send_resp(204, "")
    end
  end

  defp handle_notification(%{"notificationType" => "Complaint", "complaint" => complaint}) do
    Logger.info("Recieved complaint for email " <> inspect(complaint["complainedRecipients"]))

    complaint["complainedRecipients"] |> Enum.each(&unsubscribe_email(&1["emailAddress"]))
  end
  defp handle_notification(%{"notificationType" => "Bounce", "bounce" => bounce}) do
    Logger.info("Recieved bounce for email " <> inspect(bounce["bouncedRecipients"]))

    bounce["bouncedRecipients"] |> Enum.each(&unsubscribe_email(&1["emailAddress"]))
  end

  defp unsubscribe_email(email) do
    case Users.get_user_by_email(email) do
      nil ->
        nil
      user -> 
        EmailPreferences.update_user_subscription(user.id, true)
    end
  end
end