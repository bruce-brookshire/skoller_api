defmodule Skoller.Services.Notification do
  @moduledoc """
  Provides Notification utilities.
  """

  alias Skoller.Services.Notification.Ios
  alias Skoller.Services.Notification.Android

  require Logger

  @doc """
  Creates notification with either a title and body, or a simple message.

  ## Notes
   * `%{title: title, body: body}` as `msg` will send with a title and body.
   * `msg` as a `String` will send a simple message.
   * Currently only supports Apple devices.
  """
  def create_notification(device, "ios", msg, category) do
    Ios.create_notification(device, msg, category)
    |> inspect()
    |> Logger.info()
  end
  def create_notification(device, "android", msg, category) do
    Android.create_notification(device, msg, category)
    |> inspect()
    |> Logger.info()
  end
end