defmodule Skoller.Services.Notification.Android do
  @moduledoc """
  Provides Notification utilities.
  """

  alias Pigeon.FCM

  import Pigeon.FCM.Notification

  @doc """
  Creates notification with either a title and body, or a simple message.

  ## Notes
   * `%{title: title, body: body}` as `msg` will send with a title and body.
   * `msg` as a `String` will send a simple message.
  """
  def create_notification(device, msg, category, data \\ %{})
  def create_notification(device, %{title: title, body: body}, category, data) do
    device
    |> new()
    |> put_notification(%{"title" => title, "body" => body})
    |> put_collapse_key(category)
    |> put_data(data)
    |> FCM.push(on_response: fn(x) -> IO.inspect(x) end)
  end
  def create_notification(device, msg, category, data) do
    device
    |> new()
    |> put_notification(%{"body" => msg})
    |> put_collapse_key(category)
    |> put_data(data)
    |> FCM.push(on_response: fn(x) -> IO.inspect(x) end)
  end
end