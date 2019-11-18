defmodule Skoller.AirtableSyncJob do
  use GenServer

  alias Skoller.Repo
  alias Skoller.SkollerJobs.AirtableJobs
  alias Skoller.SkollerJobs.JobProfiles

  import Ecto.Query

  # This will currently run on every 5 minute interval in an hour.
  # It is NOT every 5 minutes from spin up.
  @max_rate_per_sec 5

  # This puts :jobs on the state for future calls.
  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  # This is the first call after start_link/1
  def init(state) do
    # Schedule work to be performed at some point
    schedule_work()
    {:ok, state}
  end

  # This is triggered whenever an event with :work is created.
  # It immediately reschedules itself, and then runs module.run.
  def handle_info(:work, state) do
    # Do the work you desire here
    # Reschedule once more
    schedule_work()
    require Logger
    Logger.info("Running Airtable Syncing Job: " <> to_string(Time.utc_now()))

  end

  # This creates a :work event to be processed after get_time_diff_minute/1 milliseconds.
  defp schedule_work() do
    Process.send_after(
      self(),
      :work,
      (60 / @max_rate_per_sec)
    )
  end
end
