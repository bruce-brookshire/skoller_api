defmodule SkollerWeb.Api.BounceController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Users.EmailPreferences
  alias Skoller.Users

  require Logger

  def bounce(conn, %{"notificationType" => "Bounce", "bounce" => bounce}) do
    case bounce["bounceType"] do
      "Permanent" -> 
        Logger.info("Recieved permanent bounce for email " <> inspect(bounce["bouncedRecepients"]))

        bounce["bouncedRecepients"] |> Enum.each(&unsubscribe_email(&1.emailAddress))
      _ ->
        Logger.info("Recieved non-permanent bounce for email " <> inspect(bounce["bouncedRecepients"]))
    end
    conn |> send_resp(204, "")
  end

  def bounce(conn, %{"notificationType" => "Complaint", "complaint" => complaint}) do
    Logger.info("Recieved complaint for email " <> inspect(complaint["complainedRecipients"]))

    complaint["complainedRecipients"] |> Enum.each(&unsubscribe_email(&1.emailAddress))

    conn |> send_resp(204, "")
  end

  def bounce(conn, _params) do
    conn |> send_resp(204, "")
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