defmodule Skoller.CronJobs.StudentsCountJob do
  require Logger

  use Oban.Worker,
    queue: :long_workers,
    max_attempts: 3,
    tags: ["long_worker", "students_count"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling StudentsCount Job: " <> to_string(Time.utc_now))
    Skoller.Classes.StudentsCount.update_all
    Logger.info("StudentsCount Job Complete: " <> to_string(Time.utc_now))

    :ok
  end
end
