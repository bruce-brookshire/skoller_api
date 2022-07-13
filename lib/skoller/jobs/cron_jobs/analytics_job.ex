defmodule Skoller.CronJobs.AnalyticsJob do
  require Logger

  alias Skoller.Repo
  alias Skoller.Analytics.Documents.DocumentType
  alias Skoller.Analytics.Jobs, as: SAJobs

  import Ecto.Query

  use Oban.Worker,
  queue: :short_workers,
  max_attempts: 3,
  tags: ["short_worker", "analytics_job"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling Analytics Job: " <> to_string(Time.utc_now))

    now = DateTime.utc_now

    from(j in DocumentType)
      |> Repo.all
      |> Enum.each(&SAJobs.run_analytics(&1, now))

    Logger.info("Analytics Job Complete: " <> to_string(Time.utc_now))

  end
end
