defmodule Skoller.CronJobs.ClassSetupJob do
  require Logger

  use Oban.Worker,
  queue: :short_workers,
  max_attempts: 3,
  tags: ["short_worker", "class_setup_job"]

  @impl Oban.Worker
  def perform(_args) do
    Logger.info("Scheduling Class Setup Job: (send_needs_setup_message/0, send_grow_community_messages/0, send_second_class_messages/0) " <> to_string(Time.utc_now))

    Skoller.StudentClasses.Jobs.send_needs_setup_messages()
    Skoller.StudentClasses.Jobs.send_grow_community_messages()
    Skoller.StudentClasses.Jobs.send_second_class_messages()

    :ok

  end
end
