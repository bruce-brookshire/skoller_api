defmodule Skoller.Services.Notification.Ios do
  @moduledoc """
  Provides Notification utilities.
  """

  alias Pigeon.APNS

  import Pigeon.APNS.Notification

  @doc """
  Creates notification with either a title and body, or a simple message.

  ## Notes
   * `%{title: title, body: body}` as `msg` will send with a title and body.
   * `msg` as a `String` will send a simple message.
  """
  def create_notification(device, msg, category)
  def create_notification(device, %{title: title, body: body}, category, custom // %{}) do
    ""
    |> APNS.Notification.new(device, System.get_env("APP_PUSH_TOPIC"))
    |> put_mutable_content
    |> put_alert(%{
          "title" => title,
          "body" => body
      })
    |> put_custom(custom)
    |> put_category(category)
    |> put_sound("default")
    |> APNS.push()
  end
  def create_notification(device, msg, category, custom // %{}) do
    msg
    |> APNS.Notification.new(device, System.get_env("APP_PUSH_TOPIC"))
    |> put_mutable_content
    |> put_category(category)
    |> put_sound("default")
    |> put_custom(custom)
    |> APNS.push()
  end
end