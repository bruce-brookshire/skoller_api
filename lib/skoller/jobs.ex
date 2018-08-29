defmodule Skoller.Jobs do
  @moduledoc false
  # This is passed in to Skoller.Scheduler
  alias Skoller.AssignmentNotifications
  alias Skoller.Locks
  alias Skoller.Emails

  @open_lock_mins 60

  # This function is called by Skoller.Scheduler every five minutes.
  def run() do
    now = Time.utc_now()

    now |> AssignmentNotifications.send_assignment_reminder_notifications()

    now |> Emails.send_no_classes_email()

    Locks.clear_locks(@open_lock_mins)
  end
end