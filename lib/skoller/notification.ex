defmodule Skoller.Notification do
  @moduledoc """
  Provides Notification utilities.
  """

  alias Pigeon.APNS

  import Pigeon.APNS.Notification

  require Logger

  @doc """
  Creates notification with either a title and body, or a simple message.

  ## Notes
   * `%{title: title, body: body}` as `msg` will send with a title and body.
   * `msg` as a `String` will send a simple message.
   * Currently only supports Apple devices.
  """
  def create_notification(device, msg, category)
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