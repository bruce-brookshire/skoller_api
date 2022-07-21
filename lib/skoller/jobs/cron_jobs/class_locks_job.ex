defmodule Skoller.CronJobs.ClassLocksJob do
  require Logger

  use Oban.Worker,
  queue: :short_workers,
  max_attempts: 3,
  tags: ["short_worker", "class_locks_job"]

  @open_lock_mins 60

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling Class Locks Job: " <> to_string(Time.utc_now))

    Skoller.Locks.clear_locks(@open_lock_mins)

    Logger.info("Class Locks Job Complete: " <> to_string(Time.utc_now))

    :ok
  end
end
