defmodule Skoller.CronJobs.ClassPeriodJob do
  require Logger

  use Oban.Worker,
  queue: :short_workers,
  max_attempts: 3,
  tags: ["short_worker", "class_period_job"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling Class Period Job: " <> to_string(Time.utc_now))

    DateTime.utc_now()
    |> Skoller.Periods.Jobs.evaluate_statuses()

    :ok
  end
end
