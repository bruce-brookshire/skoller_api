defmodule Skoller.Jobs do
  @moduledoc false
  # This is passed in to Skoller.Scheduler
  alias Skoller.Jobs

  # This function is called by Skoller.Scheduler every five minutes.
  def run() do
    now = Time.utc_now()

    now
    |> Jobs.SendNotifications.run()

    Jobs.ClearLocks.run()
  end
end