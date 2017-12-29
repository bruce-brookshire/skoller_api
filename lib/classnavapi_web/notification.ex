defmodule ClassnavapiWeb.Notification do
  @moduledoc """
    Provides Notification utilities.
  """

  alias Pigeon.APNS

  import Pigeon.APNS.Notification

  require Logger

  @push_topic "co.skoller.skoller"

  def create_notification(device, %{title: title, body: body}, category) do
    ""
    |> APNS.Notification.new(device, @push_topic)
    |> put_mutable_content
    |> put_alert(%{
          "title" => title,
          "body" => body
      })
    |> put_category(category)
    |> APNS.push()
    |> Kernel.to_string()
    |> Logger.info()
  end

  def create_notification(device, msg, category) do
    msg
    |> APNS.Notification.new(device, @push_topic)
    |> put_mutable_content
    |> put_category(category)
    |> APNS.push()
    |> Kernel.to_string()
    |> Logger.info()
  end
end