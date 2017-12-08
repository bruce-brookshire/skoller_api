defmodule ClassnavapiWeb.Notification do
  @moduledoc """
    Provides Notification utilities.
  """

  alias Pigeon.APNS

  @push_topic "co.skoller.skoller"

  def create_notification(device, msg) do
    msg
    |> APNS.Notification.new(device, @push_topic)
    |> APNS.push()
  end
end