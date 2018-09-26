defmodule SkollerWeb.Api.BounceController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Users.EmailPreferences
  alias Skoller.Users

  require Logger

  def bounce(conn, %{"Message" => %{"notificationType" => "Bounce", "bounce" => bounce}}) do
    Logger.info("Recieved bounce for email " <> inspect(bounce["bouncdRecipients"]))

    bounce["bouncedRecipients"] |> Enum.each(&unsubscribe_email(&1.emailAddress))

    conn |> send_resp(204, "")
  end

  def bounce(conn,  %{"Message" => %{"notificationType" => "Complaint", "complaint" => complaint}}) do
    Logger.info("Recieved complaint for email " <> inspect(complaint["complainedRecipients"]))

    complaint["complainedRecipients"] |> Enum.each(&unsubscribe_email(&1.emailAddress))

    conn |> send_resp(204, "")
  end

  def bounce(conn, params) do
    case params["SubscribeURL"] do
      nil -> 
        conn |> send_resp(403, "")
      url ->
        HTTPoison.get(url)
        conn |> send_resp(204, "")
    end
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