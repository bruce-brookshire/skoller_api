defmodule Skoller.CronJobs.AssignmentReminderJob do
  require Logger

  use Oban.Worker,
  queue: :short_workers,
  max_attempts: 3,
  tags: ["short_worker", "assignment_reminder_job"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling Assignment Reminder Job: " <> to_string(Time.utc_now))
    DateTime.utc_now
    |> Skoller.AssignmentNotifications.send_assignment_reminder_notifications()

    :ok
  end
end
