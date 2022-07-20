defmodule Skoller.CronJobs.StudentReferralsReportJob do
  require Logger

  use Oban.Worker,
    queue: :short_workers,
    max_attempts: 3,
    tags: ["short_worker", "student_referral_report"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling StudentReferralsReport Job: " <> to_string(Time.utc_now))
    Logger.info("StudentReferralsReport Job Complete: " <> to_string(Time.utc_now))
  end
end
