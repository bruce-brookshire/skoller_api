defmodule SkollerWeb.Notification do
  @moduledoc """
    Provides Notification utilities.
  """

  alias Pigeon.APNS

  import Pigeon.APNS.Notification

  require Logger

  def create_notification(device, %{title: title, body: body}, category) do
    ""
    |> APNS.Notification.new(device, System.get_env("APP_PUSH_TOPIC"))
    |> put_mutable_content
    |> put_alert(%{
          "title" => title,
          "body" => body
      })
    |> put_category(category)
    |> put_sound("default")
    |> APNS.push()
    |> inspect()
    |> Logger.info()
  end

  def create_notification(device, msg, category) do
    msg
    |> APNS.Notification.new(device, System.get_env("APP_PUSH_TOPIC"))
    |> put_mutable_content
    |> put_category(category)
    |> put_sound("default")
    |> APNS.push()
    |> inspect()
    |> Logger.info()
  end
end