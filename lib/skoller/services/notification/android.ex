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
  def create_notification(device, msg, category, data),
    do: create_notification(device, msg, Map.put(data, "category", category))

  def create_notification(device, msg, data \\ %{})

  def create_notification(device, %{title: title, body: body}, data) do
    device
    |> new()
    |> put_notification(%{"title" => title, "body" => body})
    |> put_collapse_key(data["category"])
    |> put_data(data)
    |> FCM.push(on_response: &log_result(&1))
  end

  def create_notification(device, msg, data) do
    device
    |> new()
    |> put_notification(%{"body" => msg})
    |> put_collapse_key(data["category"])
    |> put_data(data)
    |> FCM.push(on_response: &log_result(&1))
  end

  defp log_result(response) do
    case response do
      %{status: :success} ->
        nil

      %{response: response_msg} ->
        IO.puts("android resp:")
        IO.inspect(response_msg)

      _ ->
        IO.puts("android resp:")
        IO.inspect(response)
    end
  end
end
