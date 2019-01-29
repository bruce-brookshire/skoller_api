defmodule Skoller.JobHelper do

  defp get_time_diff(now, interval) do
    next_min = now.minute |> get_next_interval(interval)
    next_time = case now.minute == next_min do
      true -> get_time(now.minute + interval, now, interval)
      _ -> next_min |> get_time(now, interval)
    end
    case next_time do
      {:ok, next_time} ->
         case next_time == ~T[23:59:59.000000] do
            true ->
              Time.diff(next_time, Time.utc_now, :milliseconds) + 1000
            false ->
              Time.diff(next_time, Time.utc_now, :milliseconds)
         end
      {:error, _} -> raise("converting time from " <> now <> " failed.")
    end
  end

  defp get_time(min, now, interval) do
    case min > (60 - interval) do
      true -> now |> add_hour
      _ -> Time.new(now.hour, min, 0, 0)
    end
  end

  defp add_hour(now) do
    case now.hour + 1 do
      24 -> Time.new(23, 59, 59, 0)
      _ -> Time.new(now.hour + 1, 0, 0, 0)
    end
  end

  defp get_next_interval(min, interval) do
    case rem(min, interval) do
      0 -> min
      _ -> get_next_interval(min + 1, interval)
    end
  end
end
