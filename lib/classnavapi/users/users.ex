defmodule Classnavapi.Users do
  @moduledoc """
  The Users context.
  """

  @doc """
  Adds future notification time as notification time for v1 user routes.

  ## Examples

      iex> Classnavapi.Users.put_future_reminder_notification_time(%{"notification_time" => "10:00:00"})
      %{"notification_time" => "10:00:00", "future_reminder_notification_time" => "10:00:00"}

      iex> Classnavapi.Users.put_future_reminder_notification_time(%{"future_reminder_notification_time" => "10:00:00"})
      %{"future_reminder_notification_time" => "10:00:00"}

      iex> Classnavapi.Users.put_future_reminder_notification_time(%{"test" => "10:00:00"})
      %{"test" => "10:00:00"}

  """
  def put_future_reminder_notification_time(%{"future_reminder_notification_time" => _time} = attrs), do: attrs
  def put_future_reminder_notification_time(%{"notification_time" => time} = attrs) do
    attrs
    |> Map.put("future_reminder_notification_time", time)
  end
  def put_future_reminder_notification_time(attrs), do: attrs

end