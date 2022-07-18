defmodule Skoller.CronJobs.NoClassesJob do
  require Logger

  use Oban.Worker,
  queue: :long_workers,
  max_attempts: 3,
  tags: ["long_worker", "no_classes_job"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling No Classes Job: " <> to_string(Time.utc_now))

    DateTime.utc_now
    |> Skoller.StudentClasses.Jobs.send_no_classes_messages()

    Logger.info("No Classes Job Complete: " <> to_string(Time.utc_now))

    :ok
  end
end
