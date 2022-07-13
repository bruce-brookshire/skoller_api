defmodule Skoller.CronJobs.EmailManagerJob do
  require Logger

  use Oban.Worker,
  queue: :short_workers,
  max_attempts: 3,
  tags: ["short_worker", "email_manager_job"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling Email Manager Job: " <> to_string(Time.utc_now))

    Skoller.EmailJobs.Jobs.run_jobs()

    Logger.info("Email Manager Job Complete " <> to_string(Time.utc_now))

    :ok

  end
end
