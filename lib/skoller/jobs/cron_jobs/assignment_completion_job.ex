defmodule Skoller.CronJobs.AssignmentCompletionJob do
  require Logger

  use Oban.Worker,
  queue: :short_workers,
  max_attempts: 3,
  tags: ["short_worker", "assignment_completion_job"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling Assignment Completion Job: " <> to_string(Time.utc_now))
    Skoller.StudentAssignments.Jobs.mark_past_assignments_complete()
    Logger.info("Assignment Completion Job Complete: " <> to_string(Time.utc_now))
  end
end
