defmodule ClassnavapiWeb.Notification do
  @moduledoc """
    Provides Notification utilities.
  """

  alias Pigeon.APNS

  import Pigeon.APNS.Notification

  @push_topic "co.skoller.skoller"

  def create_notification(device, %{title: title, body: body}) do
    ""
    |> APNS.Notification.new(device, @push_topic)
    |> put_mutable_content
    |> put_alert(%{
          "title" => title,
          "body" => body
      })
    |> APNS.push()
  end

  def create_notification(device, msg) do
    msg
    |> APNS.Notification.new(device, @push_topic)
    |> put_mutable_content
    |> APNS.push()
  end
end