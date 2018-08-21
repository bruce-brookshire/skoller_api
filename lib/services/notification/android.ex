defmodule Services.Notification.Android do
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
  def create_notification(device, %{title: title, body: body}) do
    device
    |> new()
    |> put_notification(%{"title" => title, "body" => body})
    |> FCM.push()
  end
  def create_notification(device, msg) do
    device
    |> new()
    |> put_notification(%{"body" => msg})
    |> FCM.push()
  end
end