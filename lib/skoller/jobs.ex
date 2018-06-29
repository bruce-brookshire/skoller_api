defmodule Skoller.Jobs do
  
  alias Skoller.Jobs

  def run() do
    now = Time.utc_now()

    now
    |> Jobs.SendNotifications.run()

    Jobs.ClearLocks.run()
  end
end