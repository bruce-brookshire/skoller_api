defmodule Skoller.NoClassesJob do
  @moduledoc false
  # A Scheduler that runs the passed in module's `run/0` function every interval.
  # This needs to be run from a `Supervisor.Spec.worker/3` call.
  use GenServer

  alias Skoller.StudentClasses.Jobs, as: SCJobs

  # This will currently run on every 5 minute interval in an hour.
  # It is NOT every 5 minutes from spin up.
  @interval_min 5

  # This puts :jobs on the state for future calls.
  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  # This is the first call after start_link/1
  def init(state) do
    schedule_work() # Schedule work to be performed at some point
    {:ok, state}
  end

  # This is triggered whenever an event with :work is created.
  # It immediately reschedules itself, and then runs module.run.
  def handle_info(:work, state) do
    # Do the work you desire here
    schedule_work() # Reschedule once more
    require Logger
    Logger.info("Running No Classes Job: " <> to_string(Time.utc_now))

    DateTime.utc_now
    |> SCJobs.send_no_classes_messages()

    {:noreply, state}
  end

  # This creates a :work event to be processed after get_time_diff/1 milliseconds.
  defp schedule_work() do
    Process.send_after(self(), :work, Time.utc_now |> Skoller.JobHelper.get_time_diff(@interval_min))
  end
end
