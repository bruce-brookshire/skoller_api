defmodule Skoller.JobHelper do
  def get_time_diff_minute(now, interval) do
    get_next_minute(now.minute, now.minute, interval)
    |> get_time(now, interval)
    |> get_time_diff()
  end

  # Calculates the next minute a job can run based on the current time and the interval
  defp get_next_minute(cur_min, new_min, interval) when rem(new_min, interval) == 0,
    do: if(cur_min == new_min, do: new_min + interval, else: new_min)

  defp get_next_minute(cur_min, new_min, interval),
    do: get_next_minute(cur_min, new_min + 1, interval)

  # Get the next time a job can run 
  defp get_time(min, now, interval) when min > 60 - interval, do: add_hour(now.hour)
  defp get_time(min, now, _), do: Time.new(now.hour, min, 0, 0)

  # Gets the next whole hour, or sets to 23:59:59 in the case that it is midnight utc.
  # This only runs when the interval will result in more than 60 minutes in a day
  defp add_hour(curr_hour) when curr_hour == 23, do: Time.new(23, 59, 59, 0)
  defp add_hour(curr_hour), do: Time.new(curr_hour + 1, 0, 0, 0)

  # Gets the difference in time in milliseconds between now and the scheduled time
  defp get_time_diff({:ok, ~T[23:59:59.000000] = next_time}),
    do: Time.diff(next_time, Time.utc_now(), :milliseconds) + 1000

  defp get_time_diff({:ok, next_time}), do: Time.diff(next_time, Time.utc_now(), :milliseconds)

  defp get_time_diff({:error, _}),
    do: raise("converting time from " <> Time.utc_now() <> " failed.")
end
