defmodule Classnavapi.Users do

  def put_future_reminder_notification_time(%{"future_reminder_notification_time" => _time} = attrs), do: attrs
  def put_future_reminder_notification_time(%{"notification_time" => time} = attrs) do
    attrs
    |> Map.put("future_reminder_notification_time", time)
  end
  def put_future_reminder_notification_time(attrs), do: attrs

end