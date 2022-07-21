defmodule Skoller.CronJobs.TrialJob do
  require Logger

  use Oban.Worker,
  queue: :short_workers,
  max_attempts: 3,
  tags: ["short_worker", "trial_job"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling Trial job: " <> to_string(Time.utc_now))

    Skoller.Users.Trial.update_users_trial_status

    Logger.info("Trial Job Complete: " <> to_string(Time.utc_now))

    :ok
  end
end
