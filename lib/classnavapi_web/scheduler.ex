defmodule ClassnavapiWeb.Scheduler do
  use GenServer

  @interval_min 5

  def start_link(module) do
    GenServer.start_link(__MODULE__, %{jobs: module})
  end

  def init(state) do
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    schedule_work()
    require Logger
    Logger.info("Running Jobs: " <> to_string(Time.utc_now))
    state.jobs.run()
    {:noreply, state}
  end

  defp schedule_work() do
    now = Time.utc_now()
    Process.send_after(self(), :work, get_time_diff(now))
  end

  defp get_time_diff(now) do
    next_min = now.minute |> get_next_interval()
    next_time = case now.minute == next_min do
      true -> get_time(now.minute + @interval_min, now)
      _ -> next_min |> get_time(now)
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

  defp get_time(min, now) do
    case min > (60 - @interval_min) do
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

  defp get_next_interval(min) do
    case rem(min, @interval_min) do
      0 -> min
      _ -> get_next_interval(min + 1)
    end
  end
end