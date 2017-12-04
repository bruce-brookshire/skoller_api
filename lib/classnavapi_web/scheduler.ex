defmodule ClassnavapiWeb.Scheduler do
  use GenServer

  @interval_min 5

  def start_link(module) do
    GenServer.start_link(__MODULE__, %{jobs: module})
  end

  def init(state) do
    schedule_init()
    {:ok, state}
  end

  def handle_info(:work, state) do
    schedule_work()
    require Logger
    Logger.info("Running Jobs")
    state.jobs.run()
    {:noreply, state}
  end

  defp schedule_init() do
    now = Time.utc_now()
    Process.send_after(self(), :work, get_time_diff(now) * 1000)
  end

  defp schedule_work() do
    Process.send_after(self(), :work, @interval_min * 60 * 1000)
  end

  defp get_time_diff(now) do
    next_min = now.minute |> get_next_interval()
    next_time = case now.minute == next_min do
      true -> get_time(now.minute + @interval_min, now)
      _ -> next_min |> get_time(now)
    end
    case next_time do
      {:ok, next} -> Time.diff(next, Time.utc_now)
      {:error, _} -> raise("converting time from " <> now <> " failed.")
    end
  end

  defp get_time(min, now) do
    case min > (60 - @interval_min) do
      true -> Time.new(now.hour + 1, 0, 0, 0)
      _ -> Time.new(now.hour, min, 0, 0)
    end
  end

  defp get_next_interval(min) do
    case rem(min, @interval_min) do
      0 -> min
      _ -> get_next_interval(min + 1)
    end
  end
end